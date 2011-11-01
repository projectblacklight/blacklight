> The [[`uniqueKey`|http://wiki.apache.org/solr/UniqueKey]] encodes the identity semantics of a document. In database jargon, the primary key. 

The default `uniqueKey` field in Blacklight is "id", however it is possible to configure Blacklight to use a different field. To configure the `uniqueKey` field to use, you must in Blacklight, you can update the Blacklight initializer in `./config/blacklight_initializer.rb`:

```ruby
Blacklight.configure(:shared) do |config|
  config[:unique_key] = "my_custom_unique_key_field"
```

(You could also make this change "in code" by defining a `Class`-level `unique_key` method on `SolrDocument`, e.g.:
```ruby
class SolrDocument
  def self.unique_key
    "my_custom_unique_key_field"
  end
end
```
)

You must also modify the `document` request handler in Solr to map the user parameter `id` to the Solr `uniqueKey` field, e.g.:

```xml
  <!-- for requests to get a single document; use id=666 instead of q=id:666 -->
  <requestHandler name="document" class="solr.SearchHandler" >
    <lst name="defaults">
      <str name="echoParams">all</str>
      <str name="fl">*</str>
      <str name="rows">1</str>
      <str name="q">{!raw f=my_custom_unique_key_field v=$id}</str> <!-- use id=666 instead of q=id:666 -->
    </lst>
  </requestHandler>
```

## Code Standards

When writing code in Blacklight (or a dependent plugin or local app) that needs to look at the unique ID for a SolrDocument, you should always ask for someDocument.id and *not* someDocument['id'], in order for your code to work with configured unique_key, not hard-coded to a key named 'id'. 
