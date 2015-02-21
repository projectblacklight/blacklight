# Customizing the User Interface
## Layouts 

Blacklight provides a layout called "blacklight" that provides the basic scaffolding to make Blacklight operate correctly. If you replace it with your own layout, you may wish to preserve some key features of the provided layout:

Call `content_for(:head)` somewhere in your HTML <head>:
```erb
 <%= content_for(:head) %> 
```

Render flash messages in the layout - none of the Blacklight-provided templates and partials are configured to do this for you.

Provide an AJAX modal:

```erb
  <div id="ajax-modal" class="modal fade" tabindex="-1" role="dialog" aria-labelledby="modal menu" aria-hidden="true">
    <div class="modal-dialog">
      <div class="modal-content">
      </div>
    </div>
  </div>
```


## Overriding Views (templates and partials)
As a Rails Engine, you can easily override views in your app. You can see what views and partials are provided by looking in `[[./app/views|https://github.com/projectblacklight/blacklight/tree/master/app/views]]` inside the Blacklight source.

Once you find the view you'd like to change, you should create a file with the same name and relative path in your own application (e.g. if you wanted to override [[./app/views/catalog/_show_partials/_default.html.erb|https://github.com/projectblacklight/blacklight/blob/master/app/views/catalog/_show_partials/_default.html.erb]] you would create ./app/views/catalog/_show_partials/_default.html.erb in your local application. Frequently, you will start by copying the existing Blacklight view and modifying it from there.

It is generally recommended that you override as little as possible, in order to maximize your forward compatibility. Look to override either a small, focused partial template, or a helper method of partial template called from a larger template, so your application's version can call out to those same helpers or partial templates within blacklight core code. 

## Overriding the CatalogController
Overriding the Blacklight `CatalogController` implementation is easy, and the skeleton of the `CatalogController` is generated into your application for you when you install Blacklight. 

See the [[Extending or Modifying Blacklight Search Behavior]] for tips and approaches to customizing the catalog.

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

If you want to over-ride a helper method, copy the wrapper blacklight_helper into your local app, with the 'include' line, and now you can individually over-ride methods from BlacklightHelperBehavior, and the other methods you don't over-ride will still have their default implementation. 

YOUR `app/helpers/blacklight_helper.rb`

```ruby
module BlacklightHelper
  include Blacklight::BlacklightHelperBehavior

  def application_name
    "Bestest University Search"
  end
end
```
