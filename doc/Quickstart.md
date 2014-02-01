Blacklight is a Ruby on Rails Engine plugin, meaning it provides a small application that runs inside an existing Ruby on Rails project.  For notes on upgrading Blacklight, check out our [[Release Notes And Upgrade Guides]] index.

This Quickstart will walk you through installing Blacklight and Solr, and indexing a sample set of records. If you want information about configuring Blacklight to use an existing Solr index with your data in it, see the [[Blacklight configuration]] document.

## Pre-requisites
 * Ruby 1.9 or higher (consider using [[RVM|https://rvm.beginrescueend.com/rvm/install/]] or [[RBEnv|http://rbenv.org/]] to manage your Ruby version). 
 * Java 1.5 or higher (in order to run solr under a java servlet container)
 * **For Windows users**: You may want to use [RailsInstaller](http://railsinstaller.org/) to get a Ruby on Rails environment.

> NOTE: We run our continuous integration tests against Ruby 1.9.3, Ruby 2.0 and JRuby (running in 1.9 mode) using the latest release of Rails on a Redhat Linux machine. While Blacklight may work with older versions of Ruby, we can't commit ourselves to supporting them.

In addition, you should have the Bundler and Rails ruby gems installed:

```bash
$ gem install bundler
$ gem install rails
```

## Install and Use

1. Create a new rails 3 application

    ```bash
    $ rails new my_app      
    #      create  
    #      create  README
    #      create  Rakefile
    #      create  config.ru
    #      create  .gitignore
    #      create  Gemfile
    #      [...]

    $ cd my_app
    ```

    Rails automatically created an `public/index.html` file. However, Blacklight will provide a default `root` route for your application, so you probably want to remove it:

    ```bash
    $ rm public/index.html
    ```

2. Append this line to your application's `Gemfile`

    ```ruby
    gem 'blacklight'
    ```

    Especially if you are running on Linux, you may have to add `gem 'therubyracer'` to your gemfile, to get a Javascript runtime needed by the asset pipeline. 

    then, update the bundle

    ```bash
    $ bundle install
    ```

3. Install blacklight using Devise for user authentication: 

    ```bash
    $ rails generate blacklight --devise
    ```
    If you would prefer to integrate with an alternative user authentication provider, see the [[User Authentication]] documentation. You can also install with no support for logged in users simply by omitting the devise install, and generating blacklight with `rails generate blacklight` (no --devise argument).

4. Run your database migrations to create Blacklight's database tables:

    ```bash
    $ rake db:migrate
    ```

5. You will need to install and configure Solr. You can install
Blacklight's example Solr configuration (using the jetty servlet container) that is configured to work with
the Blacklight defaults:

    ```bash
    $ rails generate blacklight:jetty
    ```

    **For Windows Users: ** This step will only work on *nix platforms. You can manually download and extract a tagged version of [blacklight-jetty](https://github.com/projectblacklight/blacklight-jetty/tags). After extracting the file, you need to update the `config/jetty.yml` file to add the `jetty_home` key to your test environment, e.g.:

    ```yaml
test:
  jetty_port: <%= ENV['TEST_JETTY_PORT'] || 8888 %> 
  jetty_home: <%= ENV['TEST_JETTY_PATH'] || File.join(Rails.root, 'test_jetty') %>
  startup_wait: 15
    ```


6.  Make sure your Solr server is running. If you installed the Blacklight demo Solr/Jetty package, you can start the Jetty/Solr server using:

    ```bash
    $ cd jetty; java -jar start.jar &
    ```

6. Index some data. You can index test MARC records provided Blacklight running:

    ```bash
    $ rake solr:marc:index_test_data
    ```

7. Start up your application

    ```bash
    $ rails server
    ```

Visit the catalog at [[http://localhost:3000/catalog]]. 

[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/home.png|frame|alt=Blacklight home page]]

You should see the Blacklight interface with 30 MARC records for testing. Additional MARC records are available from the [[blacklight-data|https://github.com/projectblacklight/blacklight-data]] repository. These can be ingested into Solr using SolrMarc, 

```bash
$ rake solr:marc:index MARC_FILE=(path to file)
```

See [[Configuring and Customizing Blacklight]] for information about how to customize the Blacklight user interface, search experience, and more.