# Understanding Rails

In order to understand how Blacklight works, you should have a basic knowledge about how Rails works. In the previous section, we offered resources to develop a general understanding of Rails. In this section, we'll look at the most important concepts that contribute to the way Blacklight functions.

Blacklight is packaged as a [Rails Engine](http://guides.rubyonrails.org/engines.html), which means it is a Ruby gem that provides functionality to a Rails application, including functionality, javascript and css assets, etc. Installing Blacklight is as simple as adding the Blacklight gem to your Rails application's gemfile, and running the included `blacklight:install` generator (see Installing).

## Controllers

Blacklight generates a `CatalogController` into your application. This controller adds discovery and single-item "show" actions. This controller is where you can perform the majority of your Blacklight configuration and customization. The configuration options are discussed in future chapters. 

Blacklight also provides several controllers to the host application. These controllers respect the `CatalogController` configurations.

> Engine model and controller classes can be extended by open classing them in the main Rails application (since model and controller classes are just Ruby classes that inherit Rails specific functionality). 


## Models

As with the `CatalogController` above, Blacklight generates a `SolrDocument` model into your application. This model is used to translate Solr response documents into Rails models. Unlike many Rails models, the `SolrDocument` is not backed by an ActiveRecord row, but is merely a read-only, Ruby-friendly  representation of Solr's response.

Within the `SolrDocument` model, you can provide custom model methods, accessors, and behaviors to the documents returned from Solr.

The `SolrDocument` also provides an extension framework for conditionally adding additional behavior to documents. The extension framework is discussed in greater detail later.


## Views

Blacklight views can by customized by simply creating a new view within your application with the same name as the Blacklight view you want to override. If you wanted to override the view provided by the Blacklight `app/views/catalog/_per_page_widget.html.erb` partial, you could create the file `app/views/catalog/_per_page_widget.html.erb` in your own application. 

> When Rails looks for a view to render, it will first look in the app/views directory of the application. If it cannot find the view there, then it will check in the app/views directories of all engines which have this directory.

## Layout

Blacklight provides a generic layout to the application. 

If you're integrating Blacklight into an existing Rails application, 
Blacklight also expects the host application's layout to be responsible for rendering Rails flash messages and a shared Bootstrap modal. In addition, the layout should include:

A place for Blacklight views (and, mainly, plugins) to inject content into the <head>:

```erb
<head>
...
<%= content_for(:head) %>
...
</head>
```

The layout should also provide a Bootstrap container and row wrapper:

```erb
<div class="container">
...
<div class="row">
<%= yield %>
</div>
</div>
```


## Routes

Many Rails engines are "mounted" and are entirely isolated from the main application's routes. Blacklight routes, however, are injected directly into your application. Blacklight routes are added by a generator, and add this line to your `config/routes.rb`.

```ruby
blacklight_for :catalog
```

Mostly legacy. Allows for some greater flexibility.

## Assets

Blacklight adds assets to your application. Pick-and-choose, or override. Javascript is implemented using a pluggable approach, which we hope provides an easy way to customize behavior.


## Locales and i18n
