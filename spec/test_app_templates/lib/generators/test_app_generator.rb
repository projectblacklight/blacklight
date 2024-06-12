# frozen_string_literal: true
require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../test_app_templates', __dir__)

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
    end

    generate 'blacklight:install', options
  end

  def run_test_support_generator
    say_status("warning", "GENERATING test_support", :yellow)

    generate 'blacklight:test_support'
  end

  def add_component_template_override
    src_template = File.join(Blacklight::Engine.root, 'app', 'components', 'blacklight', 'top_navbar_component.html.erb')
    target_template = File.join('app', 'components', 'blacklight', 'top_navbar_component.html.erb')
    create_file(target_template) do
      File.read(src_template).gsub('role="navigation"', 'role="navigation" data-template-override="top_navbar_component"')
    end
  end
end
