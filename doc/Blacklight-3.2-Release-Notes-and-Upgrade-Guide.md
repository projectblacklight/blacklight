## Overview

Blacklight 3.2 introduces a number of new features to Blacklight, including the Rails asset pipeline, a configuration refactor, and support for Solr 3.x by default.

### Upgrading to Rails 3.1

If you are still using Rails 3.0, you should first update your project to work with Rails 3.1. Start by fixing any Rails 3.0 deprecation warnings (as those features may no longer exist or fail silently in Rails 3.1). There are some good resources to help you with the upgrade (e.g. [[http://railscasts.com/episodes/282-upgrading-to-rails-3-1?view=asciicast]]). 

### Assets (CODEBASE-363)
Blacklight 3.2 uses the Rails 3.1 asset pipeline for all assets, stylesheets and javascript. The CSS has been refactored and now uses SCSS to enable easy changing of some common parameters/colors. In addition, it no longer uses YUI-grids CSS framework. (Instead it uses Susy grid css framework).

What does this mean for you?

* Small (hopefully) upgrade costs.

* Use of the asset pipeline to compress and streamline all css files into one.

* Easier theming of blacklight.

After having upgraded to BL 3.2 (and Rails 3.1), the first thing you should do is upgrade to use the asset pipeline. The Blacklight gem's standard behavior for including CSS and Javascript in your app **requires the asset pipeline**. (Of course, if you don't  use the CSS or Javascript distributed with Blacklight, or want to roll your own custom way to include it, you could choose to continue without using the asset pipeline) 

Run the Blacklight generator to upgrade from Blacklight 3.1 to 3.2:
```
$ rails g blacklight
```

This should update the `application.css` and `application.js` files with references to the new Blacklight assets. You will still need to move or update your local assets and customizations. 

**Note**

* Now, if you have  you will need to change your layout to use the new ids, look at: [app/views/layouts/blacklight.html.erb](https://github.com/projectblacklight/blacklight/blob/master/) for reference on the new tags (#page, #bd, #hd, #footer, #main, #main_container, #sidebar). The old yui tags have no meaning in the new css.

* This also means that any local CSS that overrides Blacklight's CSS, if your uses the old yui-grids id's in your CSS selectors, you probably want to change them to use the new id's. (#doc, #doc2, etc,, as well as any .yui-*)

* You will need to remove the line `require "yui"` from your `./app/assets/stylesheets/application.css`. In previous versions, Blacklight provided the YUI css library as part of the gem. In Blacklight 3.2, because the Blacklight is no longer using YUI, this has been removed. If you wish to continue using YUI, you will need to provide your own copy in your application. You can download the [Blacklight 3.1 YUI file](https://github.com/projectblacklight/blacklight/blob/release-3.1/app/assets/stylesheets/yui.css) or from the (Yahoo YUI site)[http://developer.yahoo.com/yui/2/].

### Per-controller configuration (CODEBASE-365)

In previous versions of Blacklight, configuring Blacklight was done using a global configuration hash called `Blacklight.config` (created in `config/initializers/blacklight_config.rb`). Blacklight 3.2 deprecates this global configuration in favor of a per-controller, DSL-style configuration. Support for the old-style configuration is  still available (meaning, if you do absolutely nothing, Blacklight will convert Blacklight.config into the new-style configuration, and your application will probably continue to work), but we strongly recommend applications switch to the new-style configuration.

The two major changes are moving from the global configuration (`Blacklight.config`) to a Controller-specific method (`blacklight_config`) and replacing the hash-based access with an OpenStruct-based domain-specific language. The new style maintains many of the old semantics, but should be better structured and more clear.

On your CatalogController, you can configure the Blacklight Catalog:

```ruby
class CatalogController < ApplicationController  

  include Blacklight::Catalog

  configure_blacklight do |config|
    config.default_solr_params = { 
      :qt => 'search',
      :rows => 10 
    }

    # solr field configuration for search results/index views
    config.index.show_link = 'title_display'
    config.index.record_display_type = 'format'

    # solr field configuration for document/show views
    config.show.html_title = 'title_display'
    config.show.heading = 'title_display'
    config.show.display_type = 'format'

  # ....
  end

# ...
end

```


#### Creating a new configuration

An example of the new style configuration is available at 
[[https://github.com/projectblacklight/blacklight/blob/master/lib/generators/blacklight/templates/catalog_controller.rb]] and shows most of the ways one can use the new configuration.

There are helper methods for adding field configuration (facets, index, and show fields) as well as search and sort fields. All of these methods accept a variety of inputs and should be used in local applications in whatever form is most clear.

Field + configuration hash

```ruby
config.add_facet_field 'format', :label => 'Format' 
```

Configuration hash

```ruby
config.add_sort_field :sort => 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
```

Field + block

```ruby
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

#### Using the new configuration

Within a controller, the configuration can be accessed using the method `blacklight_config`, which is also exposed to helpers or views as a helper method.

Outside of a controller context (which should be rare, and likely undesirable), the configuration is exposed at the class level as well, e.g.:

```ruby
CatalogController.blacklight_config
```

Some configuration-driven helper methods have also been moved to the configuration object:

```ruby
blacklight_config.default_search_field
blacklight_config.default_sort_field
blacklight_config.max_per_page 
```

The Blacklight field configuration are stored as ordered hashes, with a key corresponding to the field name:

```ruby
CatalogController.blacklight_config.facet_fields

# {
#     "format" => #<Blacklight::Configuration::FacetField:0x1025a0c78
#        :label => "Format",
#        :field => "format"
#     >,
#     "pub_date" => #<Blacklight::Configuration::FacetField:0x1025a7aa0
#        :label => "Publication Year",
#        :field => "pub_date"
#    >,
# ...
```

Values can be accessed using OpenStruct methods or as a Hash:
 
```ruby
CatalogController.blacklight_config.facet_fields["format"].label # == "Format"
CatalogController.blacklight_config.facet_fields["format"][:label] # == "Format"
```

### Using the new-style config in local overrides
If you have overriden views or helpers in your local application and access `Blacklight.config` directly, you will need to update your overrides. In general, you should be able to search for references to `Blacklight.config` in your local application, replace it with the controller-level method `blacklight_config` and possibly fix up some naming differences.

### Facet refactor
Facet helpers and views have been refactored to take advantage of the new configuration style and new features in Rails. 

The old `_facet_limit` view has been split in two,

* `_facet_limit` : the partial to display the facet values
* `_facet_layout` : a 'partial layout' that displays the facet structure and headers

In the facet configuration, you can specify the partial to use to render a facet:
```ruby
config.add_facet_field 'format', :label => 'Format', :partial => 'my_custom_format_facet_display_partial'
``` 

### Solr 3.5 (CODEBASE-345)
Blacklight-jetty has been updated to Solr 3.5 (previously it was still Solr 1.4). Blacklight is still compatible with both Solr 1.x and 3.x, but the demo application is based on a Solr 3.x configuration.

#### SolrMarc 2.3.1
Older versions of SolrMarc were incompatible with Solr 3.x. Blacklight is now distributed with SolrMarc 2.3.1. But previous versions of Blacklight erroneously copied a SolrMarc.jar into your local app's lib/SolrMarc.jar when installing Blacklight. 

If you have a previously installed Blacklight, unless you have intentionally installed a local compile of SolrMarc.jar, you should remove the file at local ./lib/SolrMarc.jar, so your app will use the latest version of SolrMarc shipped with Blacklight.



### Other changes

* [CODEBASE-325](http://jira.projectblacklight.org/jira/browse/CODEBASE-325) - Allow Blacklight to function correctly when no user authentication system is provided
* [CODEBASE-362](http://jira.projectblacklight.org/jira/browse/CODEBASE-362) - Blacklight facets do not work with integer-type fields
* [CODEBASE-367](http://jira.projectblacklight.org/jira/browse/CODEBASE-367) - Pull in Hydra's jettywrapper to manage jetty
* [CODEBASE-369](http://jira.projectblacklight.org/jira/browse/CODEBASE-369) - Advanced Search has an incompatible character encoding issue under ruby 1.9
* [CODEBASE-371](http://jira.projectblacklight.org/jira/browse/CODEBASE-371) - SolrHelper#get_solr_response_for_field_values does not adequately escape value lists
* [CODEBASE-375](http://jira.projectblacklight.org/jira/browse/CODEBASE-375) - fix rake solr:marc:index task and generator to use distro SolrMarc.jar
* [CODEBASE-376](http://jira.projectblacklight.org/jira/browse/CODEBASE-376) - Look at the did_you_mean.feature scenarios, review for accuracy.
* [CODEBASE-377](http://jira.projectblacklight.org/jira/browse/CODEBASE-377) - Convert opensearch.xml.erb to true XML builder style
* [CODEBASE-379](http://jira.projectblacklight.org/jira/browse/CODEBASE-379) - Factor out use of RSolr's pagination feature and use Solr's start/rows parameters instead
* [CODEBASE-380](http://jira.projectblacklight.org/jira/browse/CODEBASE-380) - ActionMailer deprecations

