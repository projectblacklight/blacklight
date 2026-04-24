# frozen_string_literal: true

require 'engine_cart/rake_task'
require 'pathname'

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

require 'rubocop/rake_task'
RuboCop::RakeTask.new(:rubocop)

require 'solr_wrapper'
require 'open3'

def system_with_error_handling(*args)
  Open3.popen3(*args) do |_stdin, stdout, stderr, thread|
    puts stdout.read
    raise "Unable to run #{args.inspect}: #{stderr.read}" unless thread.value.success?
  end
end

def with_solr
  # We're being invoked by the app entrypoint script and solr is already up via docker compose
  if ENV['SOLR_ENV'] == 'docker-compose'
    yield
  elsif system('docker compose -v')
    # We're not running `docker compose up' but still want to use a docker instance of solr.
    begin
      puts "Starting Solr"
      system_with_error_handling "docker compose up -d solr"
      yield
    ensure
      puts "Stopping Solr"
      system_with_error_handling "docker compose stop solr"
    end
  else
    SolrWrapper.wrap do |solr|
      solr.with_collection do
        yield
      end
    end
  end
end

def blacklight_root
  Pathname(__dir__).join('..').expand_path
end

def blacklight_propshaft_css_output
  blacklight_root.join('app/assets/stylesheets/blacklight/propshaft.css')
end

def blacklight_bootstrap_stylesheets_path
  Gem::Specification.find_all_by_name('bootstrap').max_by(&:version)&.full_gem_path&.then do |path|
    File.join(path, 'assets/stylesheets')
  end
end

# rubocop:disable Rails/RakeEnvironment
desc "Run test suite"
task :ci do
  with_solr do
    Rake::Task['blacklight:internal:seed'].invoke
    Rake::Task['blacklight:coverage'].invoke
  end
end

namespace :blacklight do
  namespace :assets do
    desc 'Build the Propshaft-compatible Blacklight stylesheet'
    task :build_propshaft_css do
      begin
        require 'sassc'
      rescue LoadError
        abort 'Missing dependency: install the `sassc` gem to build blacklight/propshaft.css'
      end

      bootstrap_stylesheets_path = blacklight_bootstrap_stylesheets_path
      abort 'Could not locate the `bootstrap` gem stylesheets to build blacklight/propshaft.css' unless bootstrap_stylesheets_path

      source = <<~SCSS
        $logo-image: url("logo.png");
        @import "bootstrap";
        @import "blacklight/blacklight";
      SCSS

      css = SassC::Engine.new(
        source,
        syntax: :scss,
        load_paths: [
          blacklight_root.join('app/assets/stylesheets').to_s,
          bootstrap_stylesheets_path
        ],
        style: :compressed,
        filename: 'blacklight_propshaft.scss'
      ).render.sub(/^\uFEFF/, '')

      output = blacklight_propshaft_css_output
      File.write(output, css)
      puts "Wrote #{output.relative_path_from(blacklight_root)}"
    end
  end

  desc "Run tests with coverage"
  task :coverage do
    ENV['COVERAGE'] = 'true'
    Rake::Task["spec"].invoke
  end

  namespace :internal do
    desc 'Index seed data in test app'
    task seed: ['engine_cart:generate'] do
      within_test_app do
        system "bin/rake blacklight:index:seed"
      end
    end
  end

  desc 'Run Solr and Blacklight for interactive development'
  task :server, [:rails_server_args] => ['engine_cart:generate'] do |_t, args|
    with_solr do
      Rake::Task['blacklight:internal:seed'].invoke

      within_test_app do
        puts "Starting Blacklight (Rails server)"
        system "bin/rails s #{args[:rails_server_args]}"
      rescue Interrupt
        # We expect folks to Ctrl-c to stop the server so don't barf at them
        puts "\nStopping Blacklight (Rails server)"
      end
    end
  end
end
# rubocop:enable Rails/RakeEnvironment
