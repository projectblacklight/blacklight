require 'rails/generators'

class TestAppGenerator < Rails::Generators::Base
  source_root File.expand_path("../../../../test_app_templates", __FILE__)

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
    gem 'blacklight_marc', ">= 0.0.9", :github => 'projectblacklight/blacklight_marc'

    Bundler.with_clean_env do
      run "bundle install"
    end

    generate 'blacklight:install', '--devise --marc'
  end

  def run_test_support_generator
    say_status("warning", "GENERATING test_support", :yellow)       

    generate 'blacklight:test_support'
  end
end
