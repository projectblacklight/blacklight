# frozen_string_literal: true

require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path('../../../spec/test_app_templates', __dir__)

  def remove_index
    remove_file "public/index.html"
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    Bundler.with_unbundled_env do
      run "bundle install"
    end
    options = '--devise'
    if ENV['BLACKLIGHT_API_TEST'].present?
      options += ' --skip-assets'
    end

    generate 'blacklight:install', options
  end

  def run_test_support_generator
    say_status("warning", "GENERATING test_support", :yellow)

    generate 'blacklight:test_support'
  end

  def add_local_assets_for_propshaft
    return unless defined?(Propshaft)

    run "yarn add #{Blacklight::Engine.root}"
  end

  def add_component_template_override
    src_template = File.join(Blacklight::Engine.root, 'app', 'components', 'blacklight', 'top_navbar_component.html.erb')
    target_template = File.join('app', 'components', 'blacklight', 'top_navbar_component.html.erb')
    create_file(target_template) do
      File.read(src_template).gsub('role="navigation"', 'role="navigation" data-template-override="top_navbar_component"')
    end
  end

  def add_custom_view
    copy_file 'app/components/blacklight/gallery/document_component.rb'
    copy_file 'app/components/blacklight/icons/gallery_component.rb'

    inject_into_file 'app/controllers/catalog_controller.rb', after: "configure_blacklight do |config|" do
      "\n    config.view.gallery(document_component: Blacklight::Gallery::DocumentComponent)\n"
    end
  end
end
