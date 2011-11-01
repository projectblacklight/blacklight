## Discovery
### Search Features
Blacklight uses Solr as its "search engine". More information about Solr is available at the [[Solr web site|http://lucene.apache.org/solr/]]

* Search queries can be targeted at configurable fields (or sets of fields) to return precise search results. Advanced search capabilities are provided through the [[Advanced Search Add-On|https://github.com/projectblacklight/blacklight_advanced_search]] 
[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/search_fields.png|frame|alt=Search fields in action]]

```ruby
  # Now we see how to over-ride Solr request handler defaults, in this
  # case for a BL "search field", which is really a dismax aggregate
  # of Solr search fields. 
  config[:search_fields] << {
    :key => 'title',     
    # solr_parameters hash are sent to Solr as ordinary url query params. 
    :solr_parameters => {
      :"spellcheck.dictionary" => "title"
    },
    # :solr_local_parameters will be sent using Solr LocalParams
    # syntax, as eg {! qf=$title_qf }. This is neccesary to use
    # Solr parameter de-referencing like $title_qf.
    # See: http://wiki.apache.org/solr/LocalParams
    :solr_local_parameters => {
      :qf => "$title_qf",
      :pf => "$title_pf"
    }
  }
```

>  Source: [[./config/initializers/blacklight_config.rb|https://github.com/projectblacklight/blacklight/blob/master/lib/generators/blacklight/templates/config/blacklight_config.rb#L155]]


- Faceted search allows users to constrain searches by controlled vocabulary items
[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/search_facets.png|frame|alt=Search facets in action]]

```ruby
  # solr fields that will be treated as facets by the blacklight application
  #   The ordering of the field names is the order of the display
  # TODO: Reorganize facet data structures supplied in config to make simpler
  # for human reading/writing, kind of like search_fields. Eg,
  # config[:facet] << {:field_name => "format", :label => "Format", :limit => 10}
  config[:facet] = {
    :field_names => (facet_fields = [
      "format",
      "pub_date",
      "subject_topic_facet",
      "language_facet",
      "lc_1letter_facet",
      "subject_geo_facet",
      "subject_era_facet"
    ]),
    :labels => {
      "format"              => "Format",
      "pub_date"            => "Publication Year",
      "subject_topic_facet" => "Topic",
      "language_facet"      => "Language",
      "lc_1letter_facet"    => "Call Number",
      "subject_era_facet"   => "Era",
      "subject_geo_facet"   => "Region"
    },
    # Setting a limit will trigger Blacklight's 'more' facet values link.
    # * If left unset, then all facet values returned by solr will be displayed.
    # * If set to an integer, then "f.somefield.facet.limit" will be added to
    # solr request, with actual solr request being +1 your configured limit --
    # you configure the number of items you actually want _displayed_ in a page.    
    # * If set to 'true', then no additional parameters will be sent to solr,
    # but any 'sniffed' request limit parameters will be used for paging, with
    # paging at requested limit -1. Can sniff from facet.limit or 
    # f.specific_field.facet.limit solr request params. This 'true' config
    # can be used if you set limits in :default_solr_params, or as defaults
    # on the solr side in the request handler itself. Request handler defaults
    # sniffing requires solr requests to be made with "echoParams=all", for
    # app code to actually have it echo'd back to see it.     
    :limits => {
      "subject_topic_facet" => 20,
      "language_facet" => true
    }
  }
```

> Source: [[./config/initializers/blacklight_config.rb|https://github.com/projectblacklight/blacklight/blob/master/lib/generators/blacklight/templates/config/blacklight_config.rb#L39]]

* Blacklight provides basic spellcheck suggestions for poor search queries
[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/search_spellcheck.png|frame|alt=Spellchecking user queries]]

* Blacklight provides flexible mapping from user queries to solr parameters, which are easily overridable in local applications (see [[Extending or Modifying Blacklight Search Behavior]]).

```ruby
    # Each symbol identifies a _method_ that must be in
    # this class, taking two parameters (solr_parameters, user_parameters)
    # Can be changed in local apps or by plugins, eg:
    # CatalogController.include ModuleDefiningNewMethod
    # CatalogController.solr_search_params_logic << :new_method
    # CatalogController.solr_search_params_logic.delete(:we_dont_want)
    self.solr_search_params_logic = [:default_solr_parameters , :add_query_to_solr, :add_facet_fq_to_solr, :add_facetting_to_solr, :add_sorting_paging_to_solr ]
```

> Source: [[./lib/blacklight/solr_helper.rb|https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr_helper.rb#L70]]


### Other
- Stable URLs allow users to bookmark, share, and save search queries for later access
- Recent searches are saved in the Search History for quick access to previous queries
- Folder + Bookmarks allow users to collect and keep track of items as they browse
- Every Blacklight search provides RSS and [[Atom Responses]] of search results 
- Blacklight supports [[OpenSearch|http://www.opensearch.org/Home]], a collection of simple formats for the sharing of search results. The OpenSearch description document format can be used to describe a search engine so that it can be used by search client applications. The OpenSearch response elements can be used to extend existing syndication formats, such as RSS and Atom, with the extra metadata needed to return search results. (From OpenSearch Introduction)

## Access
### Export
- Cite
- Refworks
- Endnote
- Email
- SMS
- Librarian View

For compatible records, an [[OpenURL/Z39.88 COinS|http://www.zotero.org/support/dev/making_coins]] object is embedded in each document, which allows plugins like Zotero to easily extract data from the page. 

### Semantic Fields

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

### Data Formats
MaRC

## Testing


Additional features are available through [[Blacklight Add-ons]].