# frozen_string_literal: true
require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../test_app_templates', __dir__)

  def fix_sqlite3_version_requirement
    return unless Gem.loaded_specs['rails'].version.to_s <= '5.2.2'

    # Hack for https://github.com/rails/rails/issues/35153
    gemfile = File.expand_path('Gemfile')
    IO.write(gemfile, File.open(gemfile) do |f|
      text = f.read
      text.gsub(/^gem ["']sqlite3["']$/, 'gem "sqlite3", "~> 1.3.6"')
    end)
  end

  def remove_index
    remove_file "public/index.html"
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    Bundler.with_clean_env do
      run "bundle install"
    end
    options = '--devise'
    if ENV['BLACKLIGHT_API_TEST']
      options += ' --skip-assets'
      inject_into_class 'app/controllers/application_controller.rb', 'ApplicationController' do
        "  include ActionController::MimeResponds\n" # see https://github.com/projectblacklight/blacklight/issues/1894
      end
    end

    generate 'blacklight:install', options
  end

  def run_test_support_generator
    say_status("warning", "GENERATING test_support", :yellow)

    generate 'blacklight:test_support'
  end
end
