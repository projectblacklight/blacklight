Feature:
  In order to develop and extend the Blacklight GEM - I need to ensure that the changes
  I make will still allow all tests to pass in a fresh default installation. 

  Scenario: The Blacklight generator installs devise when given the -d option, and the tests pass
    When I run `rails new test_app`
    And I cd to "test_app"
    And a file named "Gemfile" with:
    """
    source "http://rubygems.org"
    gem 'rails', '>=3.0.4'
    gem 'sqlite3-ruby', :require => 'sqlite3'
    gem 'blacklight', :path => '../../../'

    # For testing
    group :development, :test do 
       gem "rspec"
       gem "rspec-rails", "~>2.5.0"       
       gem "cucumber-rails"
       gem "database_cleaner"  
       gem "capybara"
       gem "webrat"
       gem "aruba"
    end

    """  
    And I run `bundle install --local`

    Then the file "app/models/user.rb" should not exist
    And I run `rails generate blacklight -d`

    # Devise should now be installed.
    Then a file named "app/models/user.rb" should exist
    Then a directory named "app/views/devise" should exist
    Then the file "app/models/user.rb" should contain "devise"
    
    # And the user model should be setup with Blacklight
    And the file "app/models/user.rb" should contain "include Blacklight::User"

    And I run `rake db:migrate`
    
    # And I complete the setup for testing
    And I run `rails g cucumber:install`
    And I run `rails generate blacklight:jetty test_jetty -e test`
    Then a directory named "test_jetty" should exist
    And I run `rake solr:marc:index_test_data RAILS_ENV=test`
    And I run `rake blacklight:spec:with_solr`
    Then the output should contain "0 failures"
    And I remove the file "public/index.html"
    And I run `rake blacklight:cucumber:with_solr`
    Then the output should contain "81 passed"
