# Customizing Blacklight

There are lots of way to override specific behaviors and views in Blacklight. Blacklight is distributed as a Ruby gem with a Rails Engine framework built in. All customization of Blacklight behavior should be done within your application (partly as good practice, but also to not lose your changes with every new Blacklight release).

If you find that there is no other way to make your customization, please describe your problem on the [[mailing list|http://groups.google.com/group/blacklight-development]] -- we'll do the best we can to help out, and even make changes to Blacklight as needed. If you are interested in contributing code to Blacklight, see the [[Contributing to Blacklight]] page.

## Layouts 

The built-in Blacklight controllers all by default use a Rails view layout called "blacklight", that lives in the Blacklight source. This ends up being a bit confusing, but is the best way we have at present to have out of the box default using a layout with full functionality, without stepping on a possibly existing local 'application' layout. 

To change what layout the Blacklight controllers use, simply implement a method #layout_name in your local application_controller.rb that returns the name of the layout you'd like them to use. 

```ruby
    def layout_name
       "application"
    end
```

When implmeenting your own layout instead of using the stock one, you may want to look at the Blacklight app/views/layouts/blacklight.html.erb file to see what helper methods are called there, to maintain full Blacklight functionality you may want to call these same helper methods. An example would be insertion of alternate format auto-discovery link tags in the head section; if you call out to BL helpers, BL will make sure it happens.  Another example would be the sidebar_items helper; if you don't call out to that, your page won't include sidebar content such as facet lists. 

## Overriding Views (templates and partials)
As a Rails Engine, you can easily override views in your app. You can see what views and partials are provided by looking in `[[./app/views|https://github.com/projectblacklight/blacklight/tree/master/app/views]]` inside the Blacklight source.

Once you find the view you'd like to change, you should create a file with the same name and relative path in your own application (e.g. if you wanted to override [[./app/views/catalog/_show_partials/_default.html.erb|https://github.com/projectblacklight/blacklight/blob/master/app/views/catalog/_show_partials/_default.html.erb]] you would create ./app/views/catalog/_show_partials/_default.html.erb in your local application. Frequently, you will start by copying the existing Blacklight view and modifying it from there.

It is generally recommended that you override as little as possible, in order to maximize your forward compatibility. Look to override either a small, focused partial template, or a helper method of partial template called from a larger template, so your application's version can call out to those same helpers or partial templates within blacklight core code. 

## Overriding the Catalog controller
Overriding the Blacklight CatalogController implementation is easy, and the skeleton of the `CatalogController` is generated into your application for you when you install Blacklight. 

See the [[Extending or Modifying Blacklight Search Behavior]] for tips and approaches to customizing the catalog.

## Overriding Other Controllers

1. Find the controller you're interested in in blacklight's app/controllers/  . 
2. Create a file with the same name in your local app/controllers. 
3. This file requires the original class, and then re-opens it to add more methods.
 
```ruby
require "#{Blacklight.controllers_dir}/some_controller"

class SomeController < ApplicationController
   # custom code goes here
end
```

In that "custom code goes here", you can redefine certain methods (action methods or otherwise) to do something different.  You can also add new methods (again action methods or otherwise), etc. 

It's kind of hard to call 'super' to call original functionality: 

* the ruby language features here make 'super' unavailable, although you can work around that confusingly with the rails #alias_method_chain method. 
* but more importantly, action methods in particular don't really suit themselves to being over-ridden and called by super, because the original implementation often does something you'd want to change but there's no easy way to 'undo' -- calling 'render', which can only be called once. 

So basically, if you find yourself wanting to access some functionaltiy in the original implementation of a method that you also want to over-ride -- the best solution is probably to refactor Blacklight core code to put that functionality in a subsidiary method, so you can over-ride the action method entirely but call that logic from core.  Action methods should be short and sweet anyway. 


## Custom View Helpers

(This is accurate for Blacklight 3.1.1 and subsequent. Before that, things were messier). 

One of the most common things you might need to do is create a view helper -- especially to override some Blacklight behavior implemented in it's own view helpers. The first step is looking at Blacklight source to determine what view helper method you want to override. 

Blacklight comes packaged with several view helper modules. There is a BlacklightHelper in (blacklight source) app/helpers/blacklight_helper.rb , and several others that correspond to specific controller. (Note, depending on version of Rails and configuration, all helpers may get loaded for every request, even ones that are named to correspond only to a particular other controller). 

If you simply created a local helper with the same name as a helper in Blacklight, that will end up preventing the Blacklight helper from being loaded at all though, which is not what you want to do to override. 

We've structured each Blacklight view helper module into two parts to make it easy to selectively over-ride methods. For instance, here's Blacklight's app/helpers/blacklight_helper.rb:

```ruby
module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior
end
```

Now, the actual methods will be found in app/helpers/blacklight/blacklight_helper_behavior.rb instead. 

If you want to over-ride a helper method, copy the wrapper blacklight_helper into your local app, with the 'include' line, and now you can individually over-ride methods from BlacklightHelpersBehavior, and the other methods you don't over-ride will still have their default implementation. 

YOUR `app/helpers/blacklight_helper.rb`

```ruby
module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def application_name
    "Bestest University Search"
  end
end
```

One helper you might want to over-ride for customization is #render_document_partial (currently defined in [[blacklight_helper|https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight_helper.rb]]), which you can over-ride to choose differnet local partial views to display a document on search results or detail page, possibly varying depending on type of document according to your own local logic. 

## Adding in your own CSS or Javascript

You probably already have a local `app/controllers/application_controller.rb`. If you've installed the Blacklight plugin already, it probably looks something like this:
```ruby
class ApplicationController < ActionController::Base
  # Adds a few additional behaviors into the application controller 
  include Blacklight::Controller
end
```

Now create a css file called whatever you want in the application's `./public/stylesheets` directory inside the class definition, add like so:
```ruby
    class ApplicationController < ActionController::Base
        before_filter :add_my_own_assets

        protected
        def add_my_own_assets
            stylesheet_links << "my_css"

            # You can do something similar with javascript files too:
            # javascript_includes << "my_js"
        end
    end
```

## See also

* [[Extending or Modifying Blacklight Search Behavior]]
* [[Pagination]]