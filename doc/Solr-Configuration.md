# Blacklight configuration

The example Blacklight configuration is a simple application for displaying library holdings. In this section, we will describe the Blacklight configuration settings that determine how the Blacklight interface works with your data.

## Connecting to Solr

The Solr connection parameters are configured globally in `config/solr.yml`. It looks something like this:

```yaml
# config/solr.yml
development:
  url: <%= ENV['SOLR_URL'] || "http://127.0.0.1:8983/solr" %>
test: &test
  url: <%= "http://127.0.0.1:#{ENV['TEST_JETTY_PORT'] || 8888}/solr" %>
```

The configuration is used to configure [RSolr::Client](https://github.com/rsolr/rsolr/blob/master/lib/rsolr/client.rb). Available options include:

* url
* proxy
* open_timeout
* read_timeout
* retry_503
* retry_after_limit

### Dynamic configuration


Blacklight pre-parses the YAML file using ERB, which means you can use environment variables to configure the Solr location. With the default configuration, this means you can start Blacklight and point it at an external solr index without changing the `solr.yml` file:

```console
$ SOLR_URL="http://my.production.server/solr/core/" rails server
```

### Run-time configuration

The `solr.yml` configuration is applied globally to all Solr connections from your application. If you need to configure dynamic (e.g. per-user or per-controller) connections, Blacklight provides and uses instance-level accessor methods. Applications can override these accessors in By overriding these accessors, applications can provide either custom RSolr clients (e.g. [rsolr-async](https://github.com/mwmitchell/rsolr-async)) or per-user or per-controller solr connections:

```ruby
class CatalogController < ApplicationController
  include Blacklight::Catalog
  include MyApplicationRuntimeConfiguration
end

module MyApplicationRuntimeConfiguration
  def solr_repository
    @solr_repository ||= MyCustomSolrRepository.new(blacklight_config)
  end
end

class MyCustomSolrRepository < Blacklight::SolrRepository
  def blacklight_solr
    @blacklight_solr ||= RSolr::Custom::Client.new :user => current_user.id
  end
end
```


## Solr Configuration

### Schema


#### Solr Unique Key

If your solr configuration uses a unique field other than `id`, you must configure your `SolrDocument` (in app/models/solr_document.rb) to set the unique key:

```ruby
# app/models/solr_document.rb

class SolrDocument
  include Blacklight::Solr::Document

  self.unique_key = 'my_unique_key_field'
 
  ...
end
```

### Blacklight search requests

[Search Handler](http://wiki.apache.org/solr/SearchHandler)

Blacklight configuration parameters to directly add solr request parameters:
* default_solr_params
* qt
* solr_path
* document_solr_request_handler
* document_solr_path
* document_unique_id_param
* default_document_solr_params

### Request handlers

Blacklight supports rapid application development by allowing you to configure Blacklight to send every parameter in every solr request. One of the ways to productionize this is to move the static logic into Solr request handlers. [Request Handlers](http://wiki.apache.org/solr/SolrRequestHandler) are configured in the [solrconfig.xml](http://wiki.apache.org/solr/SolrConfigXml). 

Request handler parameters can be configured three different ways:

* defaults - provides default param values that will be used if the param does not have a value specified at request time.
* appends - provides param values that will be used in addition to any values specified at request time (or as defaults.
* invariants - provides param values that will be used in spite of any values provided at request time. They are a way of letting the Solr maintainer lock down the options available to Solr clients. Any params values specified here are used regardless of what values may be specified in either the query, the "defaults", or the "appends" params.

Here is an example request handler demonstrating all types of configuration:

```xml
  <requestHandler name="standard" class="solr.StandardRequestHandler">
     <lst name="defaults">
       <!-- assume they want 50 rows unless they tell us otherwise -->
       <int name="rows">50</int>
       <!-- assume they only want popular products unless they provide a different fq -->
       <str name="fq">popularity:[1 TO *]</str>
     </lst>
    <lst name="appends">
      <!-- no matter what other fq are also used, always restrict to only inStock products -->
      <str name="fq">inStock:true</str>
    </lst>
    <lst name="invariants">
      <!-- don't let them turn on faceting -->
      <bool name="facet">false</bool>
    </lst>

  </requestHandler>
```


#### Document request handler

In addition to the search request handler, we strongly encourage you to configure a request handler for retrieving single documents. This request handler can be highly optimized to remove unnecessary parameters and processing, makes it easier to understand the Solr request log, and allows you to easily change request parameters for search and single-item behaviors separately.

The blacklight document request handler looks like this:

```xml
<requestHandler name="document" class="solr.SearchHandler" >
  <lst name="defaults">
    <str name="echoParams">all</str>
    <str name="fl">*</str>
    <str name="rows">1</str>
    <bool name="facet">false</bool>
    <str name="q">{!raw f=id v=$id}</str> <!-- use id=666 instead of q=id:666 -->
  </lst>
</requestHandler>
```

If you're using Solr 4.0+, you may also consider using the [Solr Real-Time Get](https://cwiki.apache.org/confluence/display/solr/RealTime+Get) request handler.

```xml
<requestHandler name="/get" class="solr.RealTimeGetHandler">
  <lst name="defaults">
    <str name="omitHeader">true</str>
    <str name="wt">json</str>
    <str name="indent">true</str>
  </lst>
</requestHandler>
```