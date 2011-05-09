Feature:
  In order to easily add Blacklight fucntionality to a new rails app
  As a user of Rails3 and Blacklight
  I would like to use the blacklight generator.

  Scenario: The Blacklight generators create all the correct files and file modifications when executed with defaults
    When I run `rails new test_app`
    And I cd to "test_app"
    And a file named "Gemfile" with:
    """
    source "http://rubygems.org"
    gem 'rails', '>=3.0.4'
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'blacklight', :path => '../../../'
    """  
    And I run `bundle install --local`

    When I write to "app/models/user.rb" with:
    """
    class User < ActiveRecord::Base
    end
    """
    And I run `rails generate blacklight`
    Then the following files should exist:
       | config/initializers/blacklight_config.rb         |
       | config/solr.yml                                  |
       | public/images/blacklight/bg.png                  |
       | public/javascripts/blacklight/blacklight.js      |
       | public/javascripts/blacklight/jquery-1.4.2.min.js |
       | public/javascripts/blacklight/jquery-ui-1.8.1.custom.min.js |
       | public/stylesheets/blacklight/blacklight.css     |
       | public/stylesheets/blacklight/yui.css            | 
    And a directory named "public/stylesheets/blacklight/jquery" should exist
    And the file "app/models/user.rb" should contain "include Blacklight::User"
    
    # Devise should next exist in thie scenerio
    And a directory named "app/views/devise" should not exist
    And the file "app/models/user.rb" should not contain "devise"

  Scenario: The Blacklight generator functions correctly when specifying an alternate user model
    When I run `rails new test_app`
    And I cd to "test_app"
    And a file named "Gemfile" with:
    """
    source "http://rubygems.org"
    gem 'rails', '>=3.0.4'
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'blacklight', :path => '../../../'
    """  
    And I run `bundle install --local`
    And I run `rails generate model person`
    And I run `rails generate blacklight person`
    And the file "app/models/person.rb" should contain "include Blacklight::User"
    
    # Devise should not exist in thie scenerio
    And a directory named "app/views/devise" should not exist
    And the file "app/models/person.rb" should not contain "devise"

