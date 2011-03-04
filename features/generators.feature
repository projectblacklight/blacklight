Feature:
  In order to easily add Blacklight fucntionality to a new rails app
  As a user of Rails3 and Blacklight
  I would like to use the blacklight generator.

  Scenario: The Blacklight generators create all the correct files and file modifications when executed with defaults
    When I run "rails new test_app"
    And I cd to "test_app"
    And a file named "Gemfile" with:
    """
    source "http://rubygems.org"
    gem 'rails', '>=3.0.4'
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'blacklight', :path => '../../../'
    """  
    And I run "bundle install --local"

    When I write to "app/models/user.rb" with:
    """
    class User < ActiveRecord::Base
    end
    """
    And I run "rails generate blacklight"
    Then the following files should exist:
       | config/initializers/blacklight_config.rb         |
       | config/solr.yml                                  |
       | public/images/blacklight/bg.png                  |
       | public/javascripts/blacklight.js                 |
       | public/javascripts/jquery-1.4.2.min.js           |
       | public/javascripts/jquery-ui-1.8.1.custom.min.js |
       | public/stylesheets/blacklight.css                |
       | public/stylesheets/yui.css                       | 
    And a directory named "public/stylesheets/jquery" should exist
    And the file "app/models/user.rb" should contain "is_blacklight_user"
    
    # Devise should next exist in thie scenerio
    And a directory named "app/views/devise" should not exist
    And the file "app/models/user.rb" should not contain "devise"


  @really_slow_process
  Scenario: The Blacklight generator installs devise when given the -d option
    When I run "rails new test_app"
    And I cd to "test_app"
    And a file named "Gemfile" with:
    """
    source "http://rubygems.org"
    gem 'rails', '>=3.0.4'
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'blacklight', :path => '../../../'

    # For testing
    gem 'rspec-rails'	
    gem 'cucumber-rails'
    gem 'webrat'    # still needed for rspec view tests
    gem 'capybara'  # used by latest cucumber

    """  
    And I run "bundle install --local"

    Then the file "app/models/user.rb" should not exist
    And I run "rails generate blacklight -d"    

    # Devise should now be installed.
    Then a file named "app/models/user.rb" should exist
    Then a directory named "app/views/devise" should exist
    Then the file "app/models/user.rb" should contain "devise"
    
    # And the user model should be setup with Blacklight
    And the file "app/models/user.rb" should contain "is_blacklight_user"

    # And I copy over the rspec and feature tests, just in case I want to test them.
    And I run "cp -r ../../../test_app/spec ."
    And I run "cp -r ../../../test_app/features ."
    And I run "cp    ../../../test_app/Rakefile ."
    And I run "cp -r ../../../test_app/jetty ."
 
