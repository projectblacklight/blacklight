# Extending or Modifying Blacklight Search Behavior

Solr parameters used by for a given request can come from several different places. 

* Solr request handler: `solrconfig.xml` in your solr config
* Application logic: logic in the BL rails app itself

## Solr request handler

The Solr [[Request Handlers|http://wiki.apache.org/solr/SolrRequestHandler]] may be configured in the [[solrconfig.xml|http://wiki.apache.org/solr/SolrConfigXml]] and are baked into the request handler itself. Depending on how you have blacklight configured, your app may be using the same Solr request handler for all searches, or may be using different request handlers for different "search fields".  

The request handler is often set up with default parameters:

```xml
  <requestHandler name="standard" class="solr.SearchHandler" >
     <lst name="defaults">
       <str name="echoParams">explicit</str>
       <str name="rows">10</str> 
       <str name="fl">*</str>   
       <str name="facet">true</str>
       <str name="facet.mincount">1</str>
       <str name="facet.limit">30</str> 
       <str name="facet.field">access_facet</str>
       <str name="facet.field">author_person_facet</str>
       <str name="facet.field">author_other_facet</str>
       <str name="facet.field">building_facet</str>
       <str name="facet.field">callnum_1_facet</str>
       <str name="facet.field">era_facet</str>
       <str name="facet.field">format</str>
       <str name="facet.field">geographic_facet</str>
       <str name="facet.field">language</str>
       <str name="facet.field">pub_date_group_facet</str>
       <str name="facet.field">topic_facet</str>
     </lst>
  </requestHandler>
```
## Configuration

The default application logic (explained below) looks in configuration for things like the name of a the solr request handler to use, and default request parameters to send on every solr search request (or with every request from a certain blacklight search type/field). An example getting started configuration is generally installed into your app when you install Blacklight at `[[./app/controllers/catalog_controller.rb|https://github.com/projectblacklight/blacklight/blob/master/lib/generators/blacklight/templates/catalog_controller.rb]]`.

## Application logic

The logic Blacklight uses to determine how to map user-supplied parameters into Solr request parameters for a given application request is in the [[#solr_search_params method in the SolrHelper module|https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr_helper.rb#L76]]. Note that `[[CatalogController|https://github.com/projectblacklight/blacklight/blob/master/app/controllers/catalog_controller.rb]]` extends `[[SolrHelper|https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr_helper.rb]]`, so the `SolrHelper` methods become available in the `CatalogController` (and other controllers, if they extend `SolrHelper` too). 

Behind the scenes, #solr_search_params uses the `class_inheritable_accessor` method [[solr_search_params_logic|https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/solr_helper.rb#L30]]. solr_search_params_logic is essentially a class variable that is mixed into the CatalogController and provides an ordered list of methods to call that may inspect the supplied user parameters and add, remove, or modify the Solr request parameters that will be sent to an [[RSolr|https://github.com/mwmitchell/rsolr/]] object, which in turn will convert the hash into query parameters for a Solr request. One confusing thing is that RSolr and  [[RSolr-ext|https://github.com/mwmitchell/rsolr-ext]] provide their own mappings from certain custom terms to Solr-recognized request parameters. For instance, a `:per_page` key in that hash will get mapped to the Solr `&rows` parameter -- but a `:rows` key will also.  Blacklight developers have found that using these special RSolr "aliases" leads to confusion, as well as confusing bugs (if both `:per_page` and `:rows` are set in the hash, what happens can be hard to predict).  So we try to avoid using the special RSolr aliases, and just use ordinary Solr parameters in our hashes. But you may encounter older code that uses the RSolr aliases. 

There can be similar confusing behavior or bugs if one piece of code adds a key to a `Hash` using a `Symbol`, but another piece of code looks for and/or adds that same key to the `Hash` using a `String` instead. RSolr happens to accepts either one, but if both are present RSolr behavior can be unexpected. And even before it gets to RSolr, you may have code that thinks it replaced a key but did not becuase it was using the wrong form. Blacklight developers have agreed to try and always use `Symbol` based keys in hashes meant for Solr parameters, to try and avoid these problems. Longer term, we could probably make some code changes to make this kind of error less likely. 

The default `#solr_search_params_logic` is meant to handle very common cases and patterns based on simple configuration options from the controller and the user-supplied URL parameters.

* `[[blacklight_config.default_solr_params|https://github.com/projectblacklight/blacklight/blob/master/lib/generators/blacklight/templates/catalog_controller.rb#L9]]`
    * Default params sent to solr with every search, including the default :qt param, which determines which Solr request handler will be targetted. Some people like to use solrconfig.xml request handler defaults exclusively, and include only a :qt here; others find it more convenient to specify some defaults at the application level here. 
* `[[blacklight_config.search_fields|https://github.com/projectblacklight/blacklight/blob/master/lib/generators/blacklight/templates/catalog_controller.rb#L81]]`
   * Each search field will be presented in a select menu in the BL user interface search box. These 'search fields' don't neccesarily correspond 1-to-1 with Solr fields. What they instead correspond to is Solr parameter over-rides that will be used for this BL UI search field.  Those over-rides are present here. 
   * You could simply chose a different `:qt` Solr request handler for each search field, which has it's own default parameters in the sorlconfig.xml. This is what we started out doing with Solr, but found it led to much duplication of information in solrconfig.xml. 
   * You can continue using the same Solr request handler, but simply specify different parameters which will be included in the http query string sent to Solr here, with the `:solr_parameters`  key. This works fine, but some people don't like how it makes your Solr requests much longer/more complex in the Solr logs; and/or they prefer to control this Solr side instead of Application side. 
   * For the best of both worlds, although it's a bit confusing at first, you can use the `:solr_local_parameters` key to have parameters supplied to Solr using the Solr [[LocalParams|http://wiki.apache.org/solr/LocalParams]] syntax, which means you can use "parameter dereferencing"  with dollar-sign-prefixed references to variables defined in solrconfig.xml request handler. This is what the current example BL setup does. 

So the default implementation of `#solr_search_params` takes these configured parameters, combines them with certain query parameters from the current users HTTP request to the BL app, and prepares a Hash of parameters that will be sent to solr. For common use patterns, this is all you need. 

But sometimes you want to add some custom logic to `#solr_search_params` to come up with the solr params Hash in different ways. Typically to support a new UI feature of some kind, either in your local app or in a Blacklight add-on plugin you are developing. 


# Extending Blacklight::SolrHelper#solr_search_params

To add new search behaviors (e.g. authorization controls, pre-parsing query strings, etc), the easiest route is to add additional steps to the `#solr_search_params_logic`, either at the beginning of the list (to set default parameters) or at the end of the list (to force particular parameters). Because `#solr_search_params_logic` is just an ordinary array, you may perform any normal array operation (e.g. push/pop/delete/insert) to customize the parameter generation to meet your needs.

`#solr_search_params_logic` steps take two inputs, the hash of `solr_parameters` and the hash of `user_parameters` (often provided by the URL parameters), and modifies the `solr_parameters` directly, as needed. 

You can add custom solr_search_params_logic steps within your controller (or in many other places, including initializers, mixins, etc) by adding a Symbol with the name of a method (provided by the controller) you wish to use, e.g.:

*./config/initializers/blacklight_config.rb*

```ruby
class CatalogController
  self.solr_search_params_logic += :show_only_public_records
end
```
The controller must provide the method added to `solr_search_params_logic`, in this case `show_only_public_records`. It is often convenient to do this in a separate `Module` and include it into the controller:

*./app/controllers/catalog_controller.rb*

```ruby
require 'blacklight/catalog'
class CatalogController < ApplicationController 
  include Blacklight::Catalog
  include MyApplication::SolrHelper::Authorization
  
  # Instead of defining this within an initializer, you may instead wish to do it on the controller directly:
  # self.solr_search_params_logic << :show_only_public_records

  # You could also define the actual method here, but this is not recommended.
  # def show_only_public_records solr_parameters, user_parameters
  #  [...]
  # end
end
```

The included module then defines the logic method:
 
*./lib/my_application/solr_helper/authorization.rb*

```ruby
module MyApplication::SolrHelper::Authorization
#  You could also add the logic here
#  def self.included base
#    base.solr_search_params_logic << :show_only_public_records
#  end

  # solr_search_params_logic methods take two arguments
  # @param [Hash] solr_parameters a hash of parameters to be sent to Solr (via RSolr)
  # @param [Hash] user_parameters a hash of user-supplied parameters (often via `params`)
  def show_only_public_records solr_parameters, user_parameters
    # add a new solr facet query ('fq') parameter that limits results to those with a 'public_b' field of 1 
    solr_parameters[:fq] ||= []
    solr_parameters[:fq] << 'public_b:1'
  end
end
```

## Other examples

In addition to providing this behavior locally, some Blacklight plugins also extend the `#solr_search_params`:

* [[Blacklight Range Limit|https://github.com/projectblacklight/blacklight_range_limit/blob/master/lib/blacklight_range_limit/controller_override.rb]]

* A walk through on adding a checkbox limit at: http://bibwild.wordpress.com/2011/06/13/customing-blacklight-a-limit-checkbox/

* A much more complicated walk-through on adding an 'unstemmed search' checkbox limit: http://bibwild.wordpress.com/2011/06/20/customizing-blacklight-disable-automatic-stemming/

## Suppressing search results

You can configure your `solrconfig.xml` to not show results based on fields in your solr document.  For example, if you have a solr boolean field such as `show_b`, you can suppress any records that have this field present.  To do so, add:
```
<lst name="appends"><str name="fq">-show_b:["" TO *]</str></lst>
```
to the request handler in your `solrconfig.xml` file.  If you would like this to be for standard solr searches, add the above line to this request handler:
```
<requestHandler name="search" class="solr.SearchHandler" default="true">
```
By doing so, solr queries that use the "document" request handler will still give you any records with the show_b field, but solr queries with the "search" handler will not.