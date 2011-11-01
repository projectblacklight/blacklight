This page outlines the basic steps needed to upgrade your customized installation of Blacklight to work with the new Rails 3 branch available in our repository.  This is very much in beta now - and while we would love feedback, I don't recommend you use this branch in any sort of production environment. 

## Rails 3 Specific Changes:
Please see [[http://omgbloglol.com/post/353978923/the-path-to-rails-3-approaching-the-upgrade]] - for a good introduction.
 
1. Start by installing Rails3, generate a new app, make sure it works.  doing this not only proves your rails3 installation is working, but it will also get you familiar with the command line tools - which are very different now.
1. Now, create a new rails app on top of your existing application. This will make all sorts of modifications, creating and updating your Gemfile, Rakefile, application.rb, locals, new javascript, etc...  You should also remove all the files in /script/ except for rails - since these scripts are no longer used.
```bash
$ rails new my_existing_app
```

1. Routes are WAY different in rails 3.  Please see [[http://www.engineyard.com/blog/2010/the-lowdown-on-routes-in-rails-3/]]
1. Most of your application specific configuration now takes place in a file called config/application.rb  - you will need to move most of what is currently in your config/environment.rb and config/boot.rb into this new file. (see the link at the top of thie section for a good overview of how this works)
1. The lib directory is no longer auto-loaded - and the general recommendation is not to make it so (though it is possible inside of config/application.rb) - I went through and added requires methods where and when they are needed in the individual files, which is nice - because now it is far more clear what needs what.
1. Rails3 escapes strings by default.  You will have to add html_safe to any ruby string variables printed within "<%=" tags

## Other Gems that will need upgrading
1. If you were using the ExceptionNotification gem, things have changed in rails,  There is a good explanation here:
    http://stackoverflow.com/questions/3524127/exception-notification-gem-and-rails-3
1.  If your are using Rspec, you will need to upgrade it in your gem file to version 2.  And you will need to re-run the generator
```ruby
gem 'rspec', '>2.0.0'
$rails generate spec:install
```
1.  Recapcha, and Prawnto - I was previously using these as plugins, but they have good gems now, so I removed these from the plugin directory, and added them to the gemfile.
1. If you are using Marc, make sure you are running 0.4.1 - ran into some problems related to changes in the way Rails3 handles json prior to this upgrade.

## Blacklight Specific Changes
1. There is no application_helper.rb file in blacklight now.  It was moved to blacklight_helper, and its methods are made available automatically. (see blacklight/engine.rb for more information) So if you were attepting to include this file and override it, don't.  Just redefine the methods in your application_helper, and you should be fine.
1.  Remove the blacklight plugin directory from /vendor - since you will be installing in as a gem.   If you have blacklight checked out somewhere, you can point to it in your gem file as follows:
```ruby
   gem 'blacklight', :path => '../some/file/path/to/blacklight' 
```
otherwise, just reference the blacklight gem, which we will make available on rubygems shortly.
```ruby
   gem 'blacklight' 
```
1. Most of the configuration of blacklight is done through monkey patching at present.  In Virgo you would often see lines like:
```ruby
  require_dependency 'vendor/plugins/blacklight/....
```
at the top of a file that re-opened the class and made modifications to it. 
You would now need to change this to:
```ruby
  require "#{Blacklight.controllers_dir}/bookmarks_controller" For controllers, and ...
  require "#{Blacklight.models_dir}/bookmark" For models.
```
1. Blacklight no longer includes a user model or session controller.  It seems that everyone just rolls their own anyway.  So here you will need to add in whatever you need - in my case, that was just creating a user model.  Which looks like this:
```ruby
       class User < ActiveRecord::Base                                    
         include Blacklight::User
         acts_as_authentic                               
       end
```
Please also see the notes on the application controller below ...

1. Execute the Blacklight Generator   - This will add all kinds of files to your local application - including stylesheets, images, jar files, database migrations, etc..  It will try it's best to be "idempotent" as Jonathan likes to say - that it is shouldn't mess anything up to run this over and over again.  It will verify that the changes it's making are not already in place.
```bash
      $ rails generate blacklight
```
1. For the most part, you override a blacklight controller by including the class and then reopening it.  Unfortunately, the catalog controller was unique in the way it number of additional lib files it required and included, and it caused a number of problems attepting to just override it.  So a catalog controller is generated for you on installation (unless you already have one).  You catalog controller should look something like this (which allows you to easily override solrhelper and catalog controller methods)
```ruby
class CatalogController < ApplicationController
    include Blacklight::SolrHelper
    inlcude Blacklight::Catalog
     .....
 end
```
If you end up overriding a large number of solrhelper methods, you can also override the solr helpers in your own file, and then include that file.
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
     The blacklight generator, will add a line to your application controller if isn't there already which will cause the application controller to include the base controller logic for blacklight:
```ruby
     class ApplicationController < ActionController::Base
         include Blacklight::Controller
     end     
```
    This blacklight controller forces the the blacklight layout, adds the default_html_head before filter and associated helper methods, and creates a few helper methods for users.  Blacklight by no means requires the inclusion of this file.  In the case of Virgo, we do not. 

   You will most likely need to define the following methods in your application controller, paticularly if you have any sort of custom user authentication.

* `user_session` - which should return the current rails session object.
* `current_user`  - which should return a user object that includes Blacklight::User
* `new_user_session_path` - which should return the path for logging into your application
* `destroy_user_session_path` - which should return the path for logging out of your application.

SolrDocument is no longer a file in Blacklight, but rather a generated model in your application, in this way you can easily override and modify the behavior of individual documents. This is automatically created for you, I just wanted to draw you attention to it.
