If you have a Rails application as your data store, you may look to [Sunspot](http://outoftime.github.com/sunspot/) to help index your ActiveRecord models. Sunspot provides a nice DSL that makes it easy to index your models and associations. There is one gotcha, though, for using Sunspot with Blacklight. Both Sunspot and Blacklight expect the Solr uniqueKey to be in the "id" field. Sunspot will use the class of your model plus the primary key of that instance as the value for the id field. So a value for the id field may look like this: "Resource 123". 

When a Sunspot-indexed Solr is used with Blacklight your model names and primary keys are exposed in your URLs. You may want to use a different value as your id value for Blacklight to use for document recall and URLs. For instance you want to use a unique filename as your id value for Blacklight.  

You can use something like the following monkeypatch of Sunspot (1.2) by placing it in config/initializers/sunspot_monkeypatch_id.rb. It takes the value of the id field that Sunspot creates (Resource 123) and places it in the resource_id_ss field. It then overwrites the id value with the value from the filename field. The second part then takes a Solr hit and reverses it so that Sunspot can retrieve your models.

```ruby
     # for using a different value for the id field of your Solr documents
     Sunspot::Indexer.module_eval do
       alias :old_prepare :prepare
       def prepare(model)
         document = old_prepare(model)
         document.fields_by_name(:resource_id_ss).first.value = document.fields_by_name(:id).first.value
         if !document.fields_by_name(:filename).blank? and !document.fields_by_name(:filename).first.blank?
            document.fields_by_name(:id).first.value = document.fields_by_name(:filename).first.value
         end
         document
       end

       alias :old_remove :remove  
       def remove(*models)
         @connection.delete_by_id(
           models.map do |model| 
             prepare(model).fields_by_name(:id).first.value
           end
         )
       end

     end

     # to allow searching with Sunspot's DSL as well to retrieve your models
     class Sunspot::Search::Hit
       def initialize(raw_hit, highlights, search) 
         raw_hit['id'] = raw_hit['resource_id_ss']
         @class_name, @primary_key = *raw_hit['id'].match(/([^ ]+) (.+)/)[1..2]
         @score = raw_hit['score']
         @search = search
         @stored_values = raw_hit
         @stored_cache = {}
         @highlights = highlights
       end
     end
```



