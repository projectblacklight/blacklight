## Using Blacklight source checkout as gem for development


The ordinary install instructions install the BL gem (which is not
full source code) in wherever your system installs gems. 

Sometimes, especially for development, it's useful to check out
a complete copy of the blacklight source code, and link your app
to that as a 'gem' instead. 

Checkout the code:

    $ git clone git@github.com:projectblacklight/blacklight.git  


## Automatically generate a test application (and run the tests)
Blacklight comes with a bash script you can use to create a complete test application.  It supports Ruby 1.8.7, Ruby 1.9.2+, and JRuby 1.6.2.

Requirements:

  * rvm  - (https://rvm.beginrescueend.com/)
  * Java (1.5 or above)

From the root directory of your git checkout:

    $ ./test_support/bin/test.sh 1.8.7  

This bash script will create a fresh application in tmp/test_app -  Inside this test application it will run a bundle install, execute required generators, run migrations, configure the test environment, install a jetty server with test data, and execute all of blacklight's rspec and cucumber tests.  

Subsequent calls to this script will overwrite the test application. 

## Manually Installing a test/stub application 

1. Create a new rails 3 application

         $ rails new test-app      
         $ cd my_app

    Rails automatically created an `index.html` file; Blacklight will provide a default `root` route, so you probably want to remove it:

         $ rm public/index.html


2. In your local app's Gemfile, simply specify that it should find
the Blacklight gem at this source checkout location:

        gem 'blacklight', :path=>"./relative/path/to/blacklight_checkout"

    You can have the blacklight source checkout anywhere you want, referred to by absolute or relative path. You can have it inside your local app's directory if you want, or you can have it outside using a relative path beginning with "../".  If you have it inside your app's root, you can even use 'git submodule' techniques to link your app to a particular
git commit, like some of us did in Rails2 Blacklight. (But you probably don't want it in your local apps ./vendor/plugins, that'll likely confuse Rails, since it's already being referred to in your Gemfile). 

3. update the bundle

        $ bundle install


3. You also need to include some gems in your test app's Gemfile needed for running our tests:

        group :development, :test do 
          gem "rspec"
          gem "rspec-rails"    
          gem "cucumber-rails"
          gem "database_cleaner"  
          gem "capybara"
          gem "webrat"
          gem "jettywrapper"
        end

3. And some gems for using sass in the asset pipeline, inside group :assets that's already there in a rails 3.1 app, add:

         group :assets do
            gem 'therubyracer'  # not needed if you are on Windows or OSX where a JS runtime can already be found
         end


       

3. Run the cucumber generator:

        rails g cucumber:install


3. Install blacklight using Devise for user authentication: 

        $ gem install devise
        $ rails generate blacklight --devise

    If you would like to integrate with an existing user authentication provider, see [[User Authentication]].

4. Run your database migrations

        $ rake db:migrate


5. You need to install a jetty/solr with test data for testing. You can do that like this (from your stub app home directory):

        $  rails generate blacklight:jetty test_jetty -e test
        $  rake solr:marc:index_test_data RAILS_ENV=test


## Running the Tests
Now use some rake tasks that come with Blacklight to actually run the tests. Run these from your stub app:

  * `rake blacklight:spec:with_solr`
  * `rake blacklight:cucumber:with_solr` 

You can also run the tests without starting the test_jetty (however, tests will fail unless you start it yourself):

  * `rake blacklight:cucumber`
  * `rake blacklight:spec`

The standard rails tasks for cucumber/rspec are all included with 
    blacklight: prefix, and should work as expected, but using
    specs/features defined in BL plugin instead of in your local
    app. (Not every variant has a :with_solr yet). 
