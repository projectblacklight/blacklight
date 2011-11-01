## Pre-requisites
 * ruby v 1.8.7 or higher
 * git
 * java 1.5 or higher
 * access to a command prompt on the machine to install
    (preferably unix based)

In addition, you must have the Bundler and Rails ruby gems installed:

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

    Rails automatically created an `index.html` file; Blacklight will provide a default `root` route, so you probably want to remove it:

    ```bash
    $ rm public/index.html
    ```

2. Append this line to your application's `Gemfile`

    ```ruby
    gem 'blacklight'
    ```
    and update the bundle

    ```bash
    $ bundle install
    ```

3. Install blacklight using Devise for user authentication: 

    ```bash
    $ gem install devise
    $ rails generate blacklight --devise
    ```
    If you would prefer to integrate with an alternative user authentication provider, see the [[User Authentication]] documentation.

4. Run your database migrations

    ```bash
    $ rake db:migrate
    ```

5. You will need to install and configure Solr. You can install
Blacklight's example Solr configuration (using the jetty servlet container) that is configured to work with
Blacklight's defaults, like:

    ```bash
    $ rails generate blacklight:jetty
    ```

    Alternatively, you can also install your own copy of Solr or point Blacklight at an existing Solr server ( referred to in your `config/solr.yml`). The Blacklight
configuration must match your Solr configuration. In addition, Blacklight has minor expectations about the Solr configuration and schemas. You can generate the Blacklight demonstration solrconfig and schema files using:

    ```bash
    $ rails generate blacklight:solr_conf path/to/output/directory/
    ```
  
6.  Make sure your Solr server is running. If you installed the Blacklight demo Solr/Jetty package, you can start the Jetty/Solr server using:

    ```bash
    $ cd jetty && java -jar start.jar &
    $ cd ..
    ```

6. Index some data. You can index test MARC records provided Blacklight running:

    ```bash
    $ rake solr:marc:index_test_data
    ```

7. Start up your application

    ```bash
    $ rails server
    ```

Visit the catalog at [[http://localhost:3000/catalog]]
