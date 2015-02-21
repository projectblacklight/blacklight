# Configuring Blacklight to work with your Solr index

In order to fully understand this section, you should be familiar with Solr, ways to index data into Solr, how to configure request handlers, and how to change a Solr schema.  Those topics are covered in the official [Apache Solr Tutorial](http://lucene.apache.org/solr/tutorial.html).

The Blacklight example configuration is a (simplified) way to work with library data (in the MARC format), it is (hopefully) easy to reconfigure to work with your Solr index. In this section, we will describe most of the Blacklight configuration settings that determine how the Blacklight interface works with your data. Later sections demonstrate how to modify the Blacklight user experience and templates, etc.

> Note: In most of this section, we will show how to configure Blacklight to request data from Solr. While this works, and makes it easy to rapidly develop an application, we recommend eventually configuring your Apache Solr request handlers to do this instead.


## Connecting to Solr: config/solr.yml

Your Blacklight-based application will interact with your Solr index. Although Blacklight does distribute a sample jetty-based Solr instance, you will likely want to connect Blacklight to your own Solr index. The Solr index to use is specified in a configuration file, ```config/solr.yml```. If you open this file in a recently generated Blacklight application, you’ll see a default solr configured to use a single-core Solr running under jetty:

```yaml
development:
  url: http://127.0.0.1:8983/solr

test:
  url: http://127.0.0.1:8888/solr
```

When you run your Rails application in the ```development``` environment, it will try to connect to Solr at ```http://127.0.0.1:8983/solr```, and, likewise, in ```test```, it will try to connect to Solr at ```http://127.0.0.1:8888/solr```. 

This URL should point to the base path of your Solr application, and includes e.g. Solr core names (see below), but not request handler paths, etc.

Blacklight uses the RSolr gem to talk to Solr. The parameters are passed to [RSolr.connect](http://rubydoc.info/gems/rsolr/1.0.6/RSolr.connect).

### Using Blacklight with a Multicore Solr

Here's an example of using a Multi-core Solr install with Blacklight:

```yaml
development:
  url: http://127.0.0.1:8983/solr/development-core
test:
  url: http://127.0.0.1:8983/solr/test-core
```

### Running and Monitoring Solr with Foreman

You can use [foreman](http://blog.daviddollar.org/2011/05/06/introducing-foreman.html) to start up and monitor the blacklight rails app and the solr server. Here is an example Procfile:

    web: bundle exec rails s -p $PORT
    solr: bash -c "cd ./jetty; java -jar -Djetty.port=$PORT start.jar"

## Blacklight Configuration

Now that you've connected to Solr, you probably want to configure Blacklight to display your Solr fields in the search results and facets, and also use your fields for search fields, sort options. This configuration goes in your CatalogController.  By convention, this is in your Rails application, and is located at [```app/controllers/catalog_controller.rb```](https://github.com/projectblacklight/blacklight/blob/master/lib/generators/blacklight/templates/catalog_controller.rb).

The CatalogController includes functionality and templates for searching and displaying documents. The CatalogController needs to be configured so it knows about your Solr fields.

> NOTE: While most applications use only a single controller for search, it is possible to have multiple controllers with different configurations. This documentation will only discuss the simple case.

### default_solr_params

The default_solr_params are parameters that will be sent to the Solr API on all search-like requests:

```ruby
    config.default_solr_params = { 
      :qt => 'search',
      :rows => 10 
    }
```

This configuration would send the following for any request to solr:

```
http://localhost:8983/solr/select?qt=search&rows=10
```

While the default_solr_params are useful for rapid development, they are often moved into the Solr request handler for production deployments.

A counter-part to default_solr_params is default_document_solr_params, which is sent when requesting only a single document from solr. In the Blacklight example solrconfig.xml, there is a `document` requestHandler to retrieve a single document at a time. We encourage you to adopt pattern as well, but with an existing Solr installation adding a single document requestHandler may not be an option. Instead, you can modify the `default_document_solr_params` to configure the appropriate defaults:

```ruby
    # See SolrHelper#solr_doc_params
    config.default_document_solr_params = {
      :qt => 'document',
      ## These are hard-coded in the blacklight 'document' requestHandler
      # :fl => '*',
      # :rows => 1
      # :q => '{!raw f=id v=$id}' 
    }
```

Blacklight will add a query parameter called `id` containing the unique key for your document. It can be referenced as a Solr local parameter (as above) in your queries.


### Results views (index and show)


You can configure the fields and labels that are display for search results on the search and document views.

> Note: these must be STORED fields in the Solr index, and must be returned in the solr response or they will not be displayed.

There's a set of configuration parameters for the title and Blacklight template handling (discussed elsewhere):

```ruby
    # solr field configuration for search results/index views
    config.index.show_link = 'title_display'
    config.index.record_display_type = 'format'

    # solr field configuration for document/show views
    config.show.html_title = 'title_display'
    config.show.heading = 'title_display'
    config.show.display_type = 'format'
```

This configuration will use the ```title_display``` Solr field as the link text for each document.

There's a separate section for the additional fields to display:

```ruby
    # [from app/controllers/catalog_controller.rb]
    # solr fields to be displayed in the index (search results) view
    #   The ordering of the field names is the order of the display 
    config.add_index_field 'title_display', :label => 'Title:' 
    config.add_index_field 'title_vern_display', :label => 'Title:' 
    config.add_index_field 'author_display', :label => 'Author:' 
    config.add_index_field 'author_vern_display', :label => 'Author:'    

    # ...
    # And likewise for the show (single-document) view:

    config.add_show_field 'title_display', :label => 'Title:' 
    config.add_show_field 'title_vern_display', :label => 'Title:' 
    config.add_show_field 'subtitle_display', :label => 'Subtitle:'
```

[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/index_fields.png|frame|alt=Index Fields]]

#### Linking a value to a facet search

When rendering the format value in the search results, link the value to a facet search for that value:

```ruby
config.add_index_field 'format', :label => 'Format:', :link_to_search => true
```

Or specify the field to facet against, explicitly:
```ruby
config.add_index_field 'author_display', :label => 'Author:', :link_to_search => :author_facet
```

More advanced configuration should use a custom helper method (see below) to render an appropriate value.

#### Using a helper method to render the value

You can use view helpers to render the Solr values, e.g.:

```ruby
    config.add_index_field 'title_vern_display', :label => 'Title:', :helper_method => :my_helper_method
```

When Blacklight goes to display the 'title_vern_display' field, it will call ```my_helper_method``` to get the value to display. You can implement any logic you want to manipulate the solr document to return the value to display.

```ruby
module ApplicationHelper
  def my_helper_method args
    args[:document][args[:field]].upcase
  end
end
```

Your helper method receives hash with (at least) two parameters:

 - :document => the SolrDocument object
 - :field => the solr field to display


#### Solr hit highlighting 

You can trigger automatic Solr hit highlighting of results:

```ruby
    config.add_index_field 'title_vern_display', :label => 'Title:', :highlight => true
```

This will cause Blacklight to look at the Solr highlight component response for the value of this field. This assumes you've configured the highlighting component elsewhere. The [Solr Highlighting Parameters](http://wiki.apache.org/solr/HighlightingParameters) documentation discusses the Solr parameters available to you. You could add these to your default_solr_params, request handler configuration, or elsewhere.

You can have Blacklight send the most basic highlighting parameters for you, if you set:

```ruby
  config.add_field_configuration_to_solr_request!
```

This will enable the highlighting component and send 'hl.fl' parameters for the fields you wanted highlighted, but you will likely want to tweak this behavior further.

### Facet fields

Faceted search allows users to constrain searches by controlled vocabulary items
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

### Facet View Helpers [v.4.2.0+]

You can supply a :helper_method argument to configure what you would like displayed for the facet's text, e.g:

```ruby
    config.add_facet_field 'format', :label => 'Format', :helper_method => :my_helper_method
```

With the above code Blacklight will pass the facet's value into the given helper method, with which you can do anything you'd like.

```ruby
module ApplicationHelper
  def my_helper_method value
    value.upcase
  end
end
```
### Facet Queries
Blacklight also supports Solr facet queries:

[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/query_facets.png|frame|alt=Query facets in action]]

```ruby
    config.add_facet_field 'pub_date_query', :label => 'Publication Year', :query => {
      :last_5_years => { :label => 'Last 5 Years', :fq => "[#{Time.now.year-5} TO *]"}
    } 
```

The first argument (which maps to the facet field for plain facets) is used in the Blacklight URL when the facet is selected.

The :query hash maps a key to use in Blacklight URLs to a facet :label (used in the facet display) and an :fq to send to Solr as the `facet.query` and (if selected) the Solr `fq` parameter.

You can also tell Solr how to sort facets (either by [count or index](http://wiki.apache.org/solr/SimpleFacetParameters#facet.sort)):
If your data is strings, you can use this to perform an alphabetical sort of the facets.
```ruby
   config.add_facet_field :my_count_sorted_field, :sort => 'count'
   config.add_facet_field :my_index_sorted_field, :sort => 'index'
```


If you want Solr to add the configured facets and facet queries to the Solr query it sends, you should also add:

```ruby
    config.add_facet_fields_to_solr_request!  # deprecated: use add_facet_field :include_in_request instead
```

### Date-based facets

If you have date facets in Solr, you should add a hint to the Blacklight configuration:

```ruby
   config.add_facet_field :my_date_field, :date => true
```

This will trigger special date querying logic, and also use a localized date format when displaying the facet value. If you want to use a particular localization format, you can provide that as well:

```ruby
   config.add_facet_field :my_date_field, :date => { :format => :short }
```

### Tagging/Exclusion facets

From the solr docs:

> One can tag specific filters and exclude those filters when faceting. This is generally needed when doing multi-select faceting. [...]To implement a multi-select facet for doctype, a GUI may want to still display the other doctype values and their associated counts, as if the doctype:pdf constraint had not yet been applied. 
>
> Example:
>
> === Document Type ===
>
>  [ ] Word (42)
>
>  [x] PDF  (96)
>
>  [ ] Excel(11)
>
>  [ ] HTML (63)

To configure this behavior in Blacklight, 

```ruby
   config.add_facet_field :document_type_facet, :tag => 'some-tag', :ex => 'some-tag'
```

### search fields

Search queries can be targeted at configurable fields (or sets of fields) to return precise search results. Advanced search capabilities are provided through the [[Advanced Search Add-On|https://github.com/projectblacklight/blacklight_advanced_search]] 
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

### sort fields

```ruby
    config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
    config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'
```

[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/sort_fields.png|frame|alt=Sort fields in action]]

> TODO

## Solr Document


By default, Blacklight assumes the unique key field in your solr index is called `id`. You can change this by editing `app/models/solr_document.rb`:

```ruby
class SolrDocument
  include Blacklight::Solr::Document

  # self.unique_key = 'id'
  ...
end
```

If, for instance, your unique key field was 'uuid_s', this would read:

```ruby
class SolrDocument
  include Blacklight::Solr::Document

  self.unique_key = 'uuid_s'
  ...
end
```

This will instruct Blacklight to use your ```uuid_s``` field any time it needs an identifier for the document, e.g. when constructing document URLs. 

Also in SolrDocument is a set of "field semantics", which may be used in some basic metadata mapping:

```ruby
class SolrDocument
  ...

 field_semantics.merge!(    
                         :title => "title_display",
                         :author => "author_display",
                         :language => "language_facet",
                         :format => "format"
                         )
end
```

### Field Collapsing

Blacklight 4.4 adds support for Solr Field Collapsing (aka results grouping). The initial implementation requires you to explicitly configure your solr request handler (or default solr parameters) to enable grouping. 

Here are some solr request parameters to enable grouping on our demo index:

```
      :group => true,
      :'group.field' => 'pub_date_sort',
      :'group.ngroups' => true, # group.ngroups is REQUIRED.
      :'group.limit' => 3
```

If you only define a single group.field, Blacklight will detect the grouped response and use it. If there are multiple fields defined, you have to configure Blacklight to detect the correct field, e.g.:

```
    config.index.group = "pub_date_sort"
```

### Thumbnails in results display

Blacklight 4.4+ can render a representative thumbnail with a result on the search index page. 

Blacklight can pull a URL to the thumbnail from a field in Solr:

```ruby
  configure_blacklight do |config|
    config.index.thumbnail_field = :some_field_in_the_document
  end
```
 
Or using custom logic in a helper method of your own creation:

```ruby
  configure_blacklight do |config|
    config.index.thumbnail_method = :xyz
  end
```

With this configuration, the helper method `xyz` will be called with the `SolrDocument` document and a hash of caller-supplied image options.

Given that configuration, Blacklight will render a thumbnail (by default, right aligned, under the bookmark button) as a link to the document page. If no thumbnail is available (missing data in solr, the thumbnail method returned nil), the thumbnail block is not displayed at all.