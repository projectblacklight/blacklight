require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root "../spec/test_app_templates"

  def fix_travis_rails_4
    if ENV['TRAVIS']
      insert_into_file 'app/assets/stylesheets/application.css', :before =>'/*' do
        "@charset \"UTF-8\";\n"
      end
    end
  end

  def copy_blacklight_test_app_rake_task
    copy_file "lib/tasks/blacklight_test_app.rake"
  end

  def remove_index
    remove_file "public/index.html"
    remove_file 'app/assets/images/rails.png'
  end

  def run_blacklight_generator
    say_status("warning", "GENERATING BL", :yellow)

    generate 'blacklight', '--devise'
  end

  def run_test_support_generator
    say_status("warning", "GENERATING test_support", :yellow)

    generate 'blacklight:test_support'
  end

  # Add favicon.ico to asset path
  # ADD THIS LINE Rails.application.config.assets.precompile += %w( favicon.ico )
  # TO config/assets.rb
  def add_favicon_to_asset_path
    say_status("warning", "ADDING FAVICON TO ASSET PATH", :yellow)

    append_to_file 'config/initializers/assets.rb' do
      'Rails.application.config.assets.precompile += %w( favicon.ico )'
    end
  end
end
