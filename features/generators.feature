Feature:
  In order to easily add Blacklight fucntionality to a new rails app
  As a user of Rails3 and Blacklight
  I would like to use the blacklight generator.

  @bundle
  Scenario: The Blacklight generators create a series of database migrations

    When I run "rails new test_app"
    And I cd to "test_app"
    And a file named "Gemfile" with:
    """
    source "http://rubygems.org"
    gem 'rails', '3.0.4'
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'blacklight', :path => '../../../'

    """
    And I run "bundle install --local"
    And I run "rails generate blacklight"
    Then the following files should exist:
       | config/initializers/blacklight_config.rb         |
       | config/solr.yml                                  |
       | app/models/user_session.rb                       |
       | app/models/user.rb                               |
       | app/controller/users_controller.rb               |
       | public/images/blacklight/bg.png                  |
       | public/javascripts/blacklight.js                 |
       | public/javascripts/jquery-1.4.2.min.js           |
       | public/javascripts/jquery-ui-1.8.1.custom.min.js |
       | public/stylesheets/blacklight.css                |
       | public/stylesheets/yui.css                       | 
    And a directory named "public/stylesheets/jquery" should exist
    And I run "rake db:migrate"
    And I run "rake spec"
    
