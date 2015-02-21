Blacklight is a Ruby on Rails Engine plugin, meaning it provides a small application that runs inside an existing Ruby on Rails project.

This Quickstart will walk you through installing Blacklight and Solr, and indexing a sample set of records. If you want information about configuring Blacklight to use an existing Solr index with your data in it, see the [Developing Your Application](https://github.com/projectblacklight/blacklight/wiki#wiki-blacklight-configuration) section of the wiki.

## Dependencies
To get started with Blacklight, first [install Ruby](https://gorails.com/setup/#ruby) and [install Rails](https://gorails.com/setup/#rails), if you don't have it installed already. You'll need Ruby 1.9 or higher, and Rails 3.2 or higher.

To run Solr, you'll also need Java installed.

### Got Ruby?

You should have Ruby 1.9 or greater installed.

```console
$ ruby --version
  ruby 2.1.1p76 (2014-02-24 revision 45161) [x86_64-darwin13.0]
```

### Got Rails?

Blacklight works with Rails 3.2 and Rails 4.x, although we strongly encourage you to use Rails 4.

```console
$ rails --version
  Rails 4.0.3
```

### Got Java?

```console
$ java -version

java version "1.6.0_0"
IcedTea6 1.3.1 (6b12-0ubuntu6.1) Runtime Environment (build 1.6.0_0-b12)
OpenJDK Client VM (build 1.6.0_0-b12, mixed mode, sharing)
```

The output will vary, but you need to make sure you have version 1.6 or higher. If you don't have the required version, or if the java command is not found, download and install the latest version from Oracle at http://www.oracle.com/technetwork/java/javase/downloads/index.html. Make sure to install the JDK.

## Creating a new application the easy way

```console
$ mkdir projects
$ cd projects
$ rails new search_app -m https://raw.github.com/projectblacklight/blacklight/master/template.demo.rb
      create  
      create  README.rdoc
      create  Rakefile
      create  config.ru
      create  .gitignore
      create  Gemfile
      create  app
      create  app/assets/javascripts/application.js
      create  app/assets/stylesheets/application.css
      create  app/controllers/application_controller.rb
      create  app/helpers/application_helper.rb
      create  app/views/layouts/application.html.erb
      create  app/assets/images/.keep
      create  app/mailers/.keep
      create  app/models/.keep
      create  app/controllers/concerns/.keep
  
.
.
.
Your bundle is complete! Use `bundle show [gemname]` to see where a bundled
gem is installed.
$ cd search_app
```
### What Does the Easy Way Generator Do?
When you run the Rails generator for a new application, you can pass in the name of a file of template commands to be run after the base generator runs. The template file above runs through steps 2-5 of the 'Hard Way' below.

## Creating a new application the hard way

1. Create a new, blank Rails application

   ```console
   $ rails new my_new_blacklightapp
   $ cd my_new_blacklightapp
    ...
   ```

2. Append these lines to your application's `Gemfile`

    ```ruby
    gem 'blacklight', ">= 5.3.0"
    gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw]
    ```

    Especially if you are running on Linux, you may have to add `gem 'therubyracer'` to your gemfile, to get a Javascript runtime needed by the asset pipeline. 

    then, update the bundle

    ```bash
    $ bundle install
    ```

3. Install blacklight using Devise for user authentication: 

    ```bash
    $ rails generate blacklight:install --devise --marc --jettywrapper
    ```
    Including `--devise` will also generate devise-based Users into your application. If you would prefer to integrate with an alternative user authentication provider, see the [[User Authentication]] documentation.

   Including `--marc` will also generate `blacklight-marc` into your application, which adds library-specific functionality out-of-the-box. 

4. Run your database migrations to create Blacklight's database tables:

    ```console
    $ rake db:migrate
    ```


5. For the initial install of Blacklight you may need to download Jetty by running before starting it:
   
    ```console
    $ rake jetty:clean
    ```
## Easy or Hard: After creating your new application
1.  Make sure your Solr server is running. If you installed the Blacklight using the `--jettywrapper` option, you can start the Jetty/Solr server using:

    ```console
    $ rake jetty:start
    ```
   You should be able to navigate to Solr at http://localhost:8983/solr/#/blacklight-core/query

2. Index some data. You can index test the MARC records provided with Blacklight by running:

    ```console
    $ rake solr:marc:index_test_data
    ```
   Depending on the version of Solr you're using, you may see a warning that can be safely ignored:

   ```console
   Warning: Specifying binary request handling from a Solr Server that doesn't support it. Enable it in the solrconfig file for that server.
   ```
3. Start up your application

    ```console
    $ rails server
    ```

Visit the catalog at [[http://localhost:3000/catalog]]. 

![Blacklight Home Page](https://f.cloud.github.com/assets/111218/2059077/5f10e090-8b95-11e3-9cac-72d8e0e5968e.png)

You should see the Blacklight interface with 30 MARC records for testing. Additional MARC records are available from the [[blacklight-data|https://github.com/projectblacklight/blacklight-data]] repository. These can be ingested into Solr using SolrMarc, 

```console
$ rake solr:marc:index MARC_FILE=(path to file)
```

See [[Configuring and Customizing Blacklight]] for information about how to customize the Blacklight user interface, search experience, and more.