This page outlines the basic steps needed to upgrade your customized installation of Blacklight 2.x to work with Blacklight 3.x. 

## Rails 3 Specific Changes:
Please see [[http://omgbloglol.com/post/353978923/the-path-to-rails-3-approaching-the-upgrade]] - for a good introduction.
 
1. Start by installing Rails3, generate a new app, make sure it works. Doing this not only proves your rails3 installation is working, but it will also get you familiar with the command line tools - which are very different now.
1. Now, create a new rails app on top of your existing application. This will make all sorts of modifications, creating and updating your Gemfile, Rakefile, application.rb, locals, new javascript, etc...  You should also remove all the files in /script/ except for rails - since these scripts are no longer used.

```bash
$ rails new my_existing_app
```

1. Routes are WAY different in rails 3.  Please see [[http://www.engineyard.com/blog/2010/the-lowdown-on-routes-in-rails-3/]]
1. Most of your application specific configuration now takes place in a file called `config/application.rb`  - you will need to move most of what is currently in your `config/environment.rb` and `config/boot.rb` into this new file. 
1. The `lib` directory is no longer auto-loaded - and the general recommendation is not to make it so (though it is possible inside of `config/application.rb`) - I went through and added requires methods where and when they are needed in the individual files, which is nice - because now it is far more clear what needs what.
1. Rails 3 escapes strings by default.  You will have to add `#html_safe` to any ruby string variables that were created 'from scratch' rather than using a "safe" helper (e.g. `content_tag`, `link_to`) which escape the string internally.

## Other Gems that will need upgrading
1. If you were using the ExceptionNotification gem, things have changed in rails,  There is a good explanation here:
    [[http://stackoverflow.com/questions/3524127/exception-notification-gem-and-rails-3]]
1.  If your are using RSpec, you will need to upgrade it in your gem file to version 2.  And you will need to re-run the generator

    ```ruby
    gem 'rspec', '>2.0.0'
    $ rails generate rspec:install
    ```

1.  Recapcha, and Prawnto - I was previously using these as plugins, but they have good gems now, so I removed these from the plugin directory, and added them to the `Gemfile`.

1. If you are using the Marc gem, make sure you are running 0.4.1 - ran into some problems related to changes in the way Rails3 handles json prior to this upgrade.

## Blacklight Specific Changes
1. There is no `application_helper.rb` file in Blacklight now.  It was moved to `blacklight_helper`, and its methods are made available automatically. (see `blacklight/engine.rb` for more information) So if you were attempting to include this file and override it, don't.  Just redefine the methods in your own `ApplicationHelper`, and you should be fine.
1.  Remove the Blacklight plugin directory from /vendor - since you will be installing in as a gem.  Include the Blacklight gem in your `Gemfile` list and run `bundle install`:

```ruby
   gem 'blacklight' 
```

 If you have Blacklight checked out somewhere, you can point to it in your gem file as follows:
```ruby
   gem 'blacklight', :path => '../some/file/path/to/blacklight' 
```

1. Most of the customization of Blacklight is done through overriding Blacklight-provided methods and templates.  In Virgo you would often see lines like:
```ruby
  require_dependency 'vendor/plugins/blacklight/....
```
at the top of a file that re-opened the class and made modifications to it. 
You would now need to change this to:
```ruby
  require "#{Blacklight.controllers_dir}/bookmarks_controller" For controllers, and ...
  require "#{Blacklight.models_dir}/bookmark" For models.
```
1. Blacklight no longer includes a `User` model or `SessionController` out of the box. If you want Blacklight to provide user authentication services, you will need to install a separate library. Blacklight recommends Devise, and the Blacklight generator (in the next step) can be used to setup Devise for you.

If you choose to roll-your-own, you will need to add in whatever you need - in my case, that was just creating a `User` model and include the `Blacklight::User` mixin.  

```ruby
       class User < ActiveRecord::Base                                    
         include Blacklight::User
         acts_as_authentic                               
       end
```
Please also see the notes on the `ApplicationController` below ...

1. Run the Blacklight Generator   - This will add all kinds of files to your local application - including stylesheets, images, jar files, database migrations, etc..  It will try it's best to be "idempotent" - that it is shouldn't mess anything up to run this over and over again.  It will verify that the changes it's making are not already in place.
```bash
      $ rails generate blacklight (--devise, if you want Blacklight to install devise or MODEL_NAME, to point at a custom User model)
```
1. For the most part, you override a controller provided by Blacklight by including the class and then reopening it.  That said, the `CatalogController`  is generated for you into your application (unless you already have one).  Your `CatalogController` should look something like this:
```ruby
class CatalogController < ApplicationController
    inlcude Blacklight::Catalog
     .....
 end
```
If you end up overriding a large number of `SolrHelper` methods, you can also override the solr helpers in your own file, and then include that file.
```ruby
module UVA::SolrHelper
   include Blacklight::SolrHelper
   .....
end

class CatalogController < ApplicationController
   include UVA::SolrHelper
   include Blacklight::Catalog
  ....
end
```
1. Application Controller
     The Blacklight generator, will add a line to your `ApplicationController` if isn't there already which will cause the `ApplicationController` to include the base controller logic for Blacklight:
```ruby
     class ApplicationController < ActionController::Base
         include Blacklight::Controller
     end     
```
    The `Blacklight::Controller` module adds a number of helper methods, forces the the Blacklight layout, adds the `before_filter :default_html_head`.  Blacklight by no means requires the inclusion of this file.  In the case of Virgo, we do not. 

   You will most likely need to define the following methods in your application controller, particularly if you have any sort of custom user authentication.

* `user_session` - which should return the current rails session object.
* `current_user`  - which should return a user object that includes `Blacklight::User`
* `new_user_session_path` - which should return the path for logging into your application
* `destroy_user_session_path` - which should return the path for logging out of your application.

`SolrDocument` is no longer a file in Blacklight, but rather a generated model in your application, in this way you can easily override and modify the behavior of individual documents. This is automatically created for you, I just wanted to draw you attention to it.
