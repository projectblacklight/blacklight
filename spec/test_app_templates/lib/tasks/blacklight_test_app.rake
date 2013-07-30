require 'rspec/core/rake_task'
require 'cucumber/rake/task'

desc "run the blacklight gem spec"
gem_home = File.expand_path('../../../../..', __FILE__)

namespace :blacklight_test_app do

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = gem_home + '/spec/**/*_spec.rb'
    t.rspec_opts = "--colour"
    t.ruby_opts = "-I#{gem_home}/spec"
  end

  Cucumber::Rake::Task.new({:ok => 'test:prepare'}, 'Run features that should pass') do |t|
    t.cucumber_opts = gem_home + "/features/**/*.feature"
  end

  desc 'Alias for cucumber:ok'
  task :cucumber => 'cucumber:ok'

end