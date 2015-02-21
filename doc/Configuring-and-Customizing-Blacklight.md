There are lots of ways to override specific behaviors and views in Blacklight. Blacklight is distributed as a Ruby gem with a Rails Engine framework built in. All customization of Blacklight behavior should be done within your application (partly as good practice, but also to not lose your changes with every new Blacklight release).

If you find that there is no other way to make your customization, please describe your problem on the [[mailing list|http://groups.google.com/group/blacklight-development]] -- we'll do the best we can to help out, and even make changes to Blacklight as needed. If you are interested in contributing code to Blacklight, see the [[Contributing to Blacklight]] page.

## Configuration


Blacklight provides a Ruby on Rails -based interface to the Apache Solr Enterprise Search Server. More information about Solr is available at the [[Solr web site|http://lucene.apache.org/solr/]]. In order to fully understand this section, you should be familiar with Solr, ways to index data into Solr, how to configure request handlers, and how to change a Solr schema.  Those topics are covered in the official [Apache Solr Tutorial](http://lucene.apache.org/solr/tutorial.html).

Although the out-of-the-box Blacklight application is configured to work with library MARC-based data, the configuration is easy to extend and modify to meet other needs.  **All of these configurations for facet fields, index fields, solr search params logic, etc. go in your CatalogController**.  By default, this will be located at *app/controllers/catalog_controller.rb*  

**Note:** While it is sufficient to have just one CatalogController, You can actually create multiple variations of the catalog controller (ie. MusicCatalog, DvdCatalog), each with its own configuration settings and URL routing.

Once you have your Solr fields, you can then configure your Blacklight application to display arbitrary fields in different contexts

### Choose which Fields to Display in Search Results

* Displayed fields and labels can be customized on both the search results and document views.
Note that these must be STORED fields in the Solr index.

```ruby
    # [from app/controllers/catalog_controller.rb]
    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'title_display', :label => 'Title:' 
    config.add_index_field 'title_vern_display', :label => 'Title:' 
    config.add_index_field 'author_display', :label => 'Author:' 
    config.add_index_field 'author_vern_display', :label => 'Author:'    
```

### Targeting Search Queries at Configurable Fields

* Search queries can be targeted at configurable fields (or sets of fields) to return precise search results. Advanced search capabilities are provided through the [[Advanced Search Add-On|https://github.com/projectblacklight/blacklight_advanced_search]] 
[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/search_fields.png|frame|alt=Search fields in action]]

```ruby
    # [from app/controllers/catalog_controller.rb]
    # Now we see how to over-ride Solr request handler defaults, in this
    # case for a BL "search field", which is really a dismax aggregate
    # of Solr search fields. 
    
    config.add_search_field('title') do |field|
      # solr_parameters hash are sent to Solr as ordinary url query params. 
      field.solr_parameters = { :'spellcheck.dictionary' => 'title' }

      # :solr_local_parameters will be sent using Solr LocalParams
      # syntax, as eg {! qf=$title_qf }. This is neccesary to use
      # Solr parameter de-referencing like $title_qf.
      # See: http://wiki.apache.org/solr/LocalParams
      field.solr_local_parameters = { 
        :qf => '$title_qf',
        :pf => '$title_pf'
      }
    end
```

### Choosing & Configuring Facets

- Faceted search allows users to constrain searches by controlled vocabulary items
[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/search_facets.png|frame|alt=Search facets in action]]
Note that these must be INDEXED fields in the Solr index, and are generally a single token (e.g. a string).

```ruby
    # [from app/controllers/catalog_controller.rb]
    # solr fields that will be treated as facets by the blacklight application
    #   The ordering of the field names is the order of the display
    config.add_facet_field 'format', :label => 'Format' 
    config.add_facet_field 'pub_date', :label => 'Publication Year' 
    config.add_facet_field 'subject_topic_facet', :label => 'Topic', :limit => 20 
    config.add_facet_field 'language_facet', :label => 'Language', :limit => true 
```

Blacklight also supports Solr facet queries:

```ruby
    config.add_facet_field 'pub_date_query', :label => 'Publication Year', :query => {
      :last_5_years => { :label => 'Last 5 Years', :fq => "[#{Time.now.year-5} TO *]"}
    } 
```

You can also tell Solr how to sort facets (either by count or index):
Note: setting 'index' causes Blacklight to sort by count and then by index. If your data is strings, you can use this to perform an alphabetical sort of the facets.
```ruby
   config.add_facet_field :my_count_sorted_field, :sort => 'count'
   config.add_facet_field :my_index_sorted_field, :sort => 'index'
```


If you want Solr to add the configured facets and facet queries to the Solr query it sends, you should also add:

```ruby
    config.add_facet_fields_to_solr_request!
```

If you have date facets in Solr, you should add a hint to the Blacklight configuration:

```ruby
   config.add_facet_field :my_date_field, :date => true
```

This will trigger special date querying logic, and also use a localized date format when displaying the facet value. If you want to use a particular localization format, you can provide that as well:

```ruby
   config.add_facet_field :my_date_field, :date => { :format => :short }
```

### Map from User Queries to Solr Parameters

* Blacklight provides flexible mapping from user queries to solr parameters, which are easily overridden in local applications (see [[Extending or Modifying Blacklight Search Behavior]]).

```ruby
    # [from app/controllers/catalog_controller.rb]
    # Each symbol identifies a _method_ that must be in
    # this class, taking two parameters (solr_parameters, user_parameters)
    # Can be changed in local apps or by plugins, eg:
    # CatalogController.include ModuleDefiningNewMethod
    # CatalogController.solr_search_params_logic << :new_method
    # CatalogController.solr_search_params_logic.delete(:we_dont_want)
    self.solr_search_params_logic = [:default_solr_parameters , :add_query_to_solr, :add_facet_fq_to_solr, :add_facetting_to_solr, :add_sorting_paging_to_solr ]
```

> Source: [[./lib/blacklight/solr_helper.rb|https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr_helper.rb#L70]]

### Document Extension Framework

The main use case for extensions is for transforming a Document to another
format. Either to another type of Ruby object, or to an exportable string in
a certain format. 

An Blacklight::Solr::Document extension is simply a ruby module which is mixed
in to individual Document instances.  The intended use case is for documents
containing some particular format of source material, such as Marc. An
extension can be registered with your document class, along with a block
containing custom logic for which documents to apply the extension to.

```ruby
    SolrDocument.use_extension(MyExtension) {|document| my_logic_on_document(document}
```

MyExtension will be mixed-in (using ruby 'extend') only to those documents
where the block results in true.

Underlying metadata formats, or other alternative document views, are linked to from the HTML page <head>. 

# Customizing the User Interface
## Layouts 

The built-in Blacklight controllers all by default use a Rails view layout called "blacklight", that lives in the Blacklight source. This ends up being a bit confusing, but is the best way we have at present to have out of the box default using a layout with full functionality, without stepping on a possibly existing local 'application' layout. 

To change what layout the Blacklight controllers use, simply implement a method #layout_name in your local application_controller.rb that returns the name of the layout you'd like them to use. 

```ruby
# [from app/controllers/application_controller.rb]
class ApplicationController < ActionController::Base
  ...
    def layout_name
       "application"
    end
  ...
end
```

When implementing your own layout instead of using the stock one, you may want to look at the Blacklight [app/views/layouts/blacklight.html.erb](https://github.com/projectblacklight/blacklight/blob/master/app/views/layouts/blacklight.html.erb) file to see what helper methods are called there, to maintain full Blacklight functionality you may want to call these same helper methods. 

* `render_head_content` renders content within the
  html `<head>` tag, which includes document-specific alternative
formats as well as tags generated by plugins, etc.
* `sidebar_items` renders features including sidebar content, e.g. facet
  lists.
* flash messages
* user util links

## Overriding Views (templates and partials)
As a Rails Engine, you can easily override views in your app. You can see what views and partials are provided by looking in [[./app/views|https://github.com/projectblacklight/blacklight/tree/master/app/views]] inside the Blacklight source.

Once you find the view you'd like to change, you should create a file with the same name and relative path in your own application (e.g. if you wanted to override [[./app/views/catalog/_show_partials/_default.html.erb|https://github.com/projectblacklight/blacklight/blob/master/app/views/catalog/_show_partials/_default.html.erb]] you would create ./app/views/catalog/_show_partials/_default.html.erb in your local application. Frequently, you will start by copying the existing Blacklight view and modifying it from there.

It is generally recommended that you override as little as possible, in order to maximize your forward compatibility. Look to override either a small, focused partial template, or a helper method of partial template called from a larger template, so your application's version can call out to those same helpers or partial templates within blacklight core code. 

## Overriding the CatalogController
Overriding the Blacklight `CatalogController` implementation is easy, and the skeleton of the `CatalogController` is generated into your application for you when you install Blacklight. 

See the [[Extending or Modifying Blacklight Search Behavior]] for tips and approaches to customizing the catalog.

## Overriding Other Controllers

1. Find the controller you're interested in blacklight's app/controllers/  . 
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

One helper you might want to over-ride for customization is #render_document_partial (currently defined in [[blacklight_helper|https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight_helper.rb]]), which you can over-ride to choose different local partial views to display a document on search results or detail page, possibly varying depending on type of document according to your own local logic. 

## Adding in your own CSS or Javascript

Within your local application, you can use the [[Rails Asset Pipeline|http://guides.rubyonrails.org/asset_pipeline.html]] to manipulate javascript and css documents.

**todo??** better instructions for over-riding BL's built in CSS using SASS? (jrochkind thought jamesws wrote such already, but can't find them now)

The Blacklight generator added a file to your app at `./app/assets/stylesheets/blacklight.css.scss`, elements of the BL default theme can be customized or over-ridden there. If there's something you want to do but aren't sure of the best way, feel free to ask on the listserv. 


## See also

* [[Extending or Modifying Blacklight Search Behavior]]
* [[Pagination]]