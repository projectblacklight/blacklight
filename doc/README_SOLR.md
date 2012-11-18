#Solr in Blacklight

##Setting up Solr

Blacklight uses Solr as its "search engine". 
More information about Solr is available at the Solr web site ( http://lucene.apache.org/solr/)

There are three sections to this document:
* Getting Solr
* Configuring Solr
  * schema.xml
  * solrconfig.xml
* SolrMARC

### Getting Solr
Blacklight distributes a pre-configured version of Solr (with the Jetty
container) as [[blacklight-jetty|https://github.com/projectblacklight/blacklight-jetty/tags]].

You can also use an existing Solr index (with some minor modifications).
If you want to start from a new version of Solr, follow the directions from the [[Solr tutorial|http://lucene.apache.org/solr/tutorial.html]]

You should now have a usable copy of Solr.

### Configuring Solr
####Solr Schema.xml

Between the `schema.xml` and `solrconfig.xml` you can change and tune the search behavior following directions from the [[Solr wiki|http://wiki.apache.org/solr/]]. Solr comes with example schema and solrconfig files, which you can use as a starting point for configuring your local Solr application.

Blacklight expects a uniqueKey field within your Solr index,
traditionally called `id`. The name of the unique key field can be
configured in your application's `SolrDocument`.

##### Blacklight community "best practices"

Solr uses a schema.xml file to define document fields (among other things). These fields store data for searching and for result display. You can find the example/solr/conf/schema.xml file in the Solr distribution you just downloaded and uncompressed.

Documentation about the Solr schema.xml file is available at (http://wiki.apache.org/solr/SchemaXml).

  The default schema.xml file comes with some preset fields made to work with
  the example data. If you don't already have a schema.xml setup, we 
  recommend using a simplified "fields" section like this:
```xml  
	<fields>
		<field name="id" type="string" indexed="true" stored="true" required="true" />
		<field name="text" type="text" indexed="true" stored="false" multiValued="true"/>
		<field name="timestamp" type="date" indexed="true" stored="true" default="NOW" multiValued="false"/>
		<field name="spell" type="textSpell" indexed="true" stored="true" multiValued="true"/>
		<dynamicField name="*_i"  type="sint"    indexed="true"  stored="true"/>
		<dynamicField name="*_s"  type="string"  indexed="true"  stored="true" multiValued="true"/>
		<dynamicField name="*_l"  type="slong"   indexed="true"  stored="true"/>
		<dynamicField name="*_t"  type="text"    indexed="true"  stored="true" multiValued="true"/>
		<dynamicField name="*_b"  type="boolean" indexed="true"  stored="true"/>
		<dynamicField name="*_f"  type="sfloat"  indexed="true"  stored="true"/>
		<dynamicField name="*_d"  type="sdouble" indexed="true"  stored="true"/>
		<dynamicField name="*_dt" type="date"    indexed="true"  stored="true"/>
		<dynamicField name="random*" type="random" />
		<dynamicField name="*_facet" type="string" indexed="true" stored="true" multiValued="true" />
		<dynamicField name="*_display" type="string" indexed="false" stored="true" />
	</fields>
```        
	
  
  Additionally, replace all of the tags after the "fields" section, and before 
  the `</schema>` tag with this:
```xml  
	<uniqueKey>id</uniqueKey>
	<defaultSearchField>text</defaultSearchField>
	<solrQueryParser defaultOperator="OR"/>
	<copyField source="*_facet" dest="text"/>
```

  Now you have a basic schema.xml file ready. Other fields can be specified, including a primary document title (`title_display`) and format (`format`), but these are easily configured in your application's `CatalogController`.

  Fields that are "indexed" are searchable.

  Fields that are "stored" are can be viewed/displayed from the Solr search 
  results. 

  The fields with asterisks ('*') in their names are "dynamic" fields. These 
  allow you to create arbitrary tags at index time. 

  The *_facet field can be used for creating your facets. When you index, 
  simply define a field with _facet on the end:
    category_facet

  The *_display field can be used for storing text that doesn't need to be 
  indexed. An example would be the raw MARC for a record's detail view:
    raw_marc_display

  For text that will be queried (and possibly displayed), use the *_t type 
  field for tokenized text (text broken into pieces/words) or the *_s type 
  for queries that should exactly match the field contents:
    description_t
    url_s

  The Blacklight application is generic enough to work with any Solr schema, but to
  manipulate the search results and single record displays, you'll need to know the 
  stored fields in your indexed documents.

  For more information, refer to the Solr documentation: 
    http://wiki.apache.org/solr/SchemaXml


#####solrconfig.xml

Solr uses the solrconfig.xml file to define searching configurations, set cache options, etc. 
You can find the examples/solr/conf/solrconfig.xml in the distribution directory you just uncompressed.

Documentation about the solrconfig.xml file is available at (http://wiki.apache.org/solr/SolrConfigXml).

Blacklight expects two request handlers to be defined -- one to handle
general search requests and one to handle single-document lookup. The
names of these request handlers are configurable, but are called
"search" and "document" respectively, out of the box.


#####Solr Search Request Handlers

  When Blacklight does a collection search, it sends a request to a Solr 
  request handler named "search". The most important settings in this handler 
  definition are the "fl" param (field list) and the facet params.

  The "fl" param specifies which fields are returned in a Solr response.
  The facet related params set up the faceting mechanism.

  Find out more about the basic params: 
     http://wiki.apache.org/solr/DisMaxRequestHandler
  
  Find out more about the faceting params: 
    http://wiki.apache.org/solr/SimpleFacetParameters


######How the "fl" param works in Blacklight's request handlers

  Blacklight comes with a set of "default" views for rendering each document 
  in a search results page. This view simply loops through all of the fields 
  returned in each document in the Solr response. The "fl" (field list) param
  tells Solr which fields to include in the documents in the response ... 
  and these are the fields rendered in the Blacklight default views.  
  Thus, the fields you want rendered must be specified in "fl".  Note that 
  only "stored" fields will be available;  if you want a field to be rendered 
  in the result, it must be "stored" per the field definition in schema.xml.

  The "fl" parameter definition in the "search" handler looks like this:
  ```xml
    <str name="fl">id,score,author_display,(....lots of other fields)</str>
  ```  
  You may also use an asterisk plus "score":
  ```xml
    <str name="fl">*,score</str>
  ```  

######How the facet params work in Blacklight's request handlers

  In the search results view, Blacklight will look into the Solr response for 
  facets. If you specify any facet.field params in your "search" handler, 
  they will automatically get displayed in the facets list:
  ```xml
    <str name="facet.field">format</str>
    <str name="facet.field">language_facet</str>
  ```  


#####Blacklight's "search" request handler: for search results

  When Blacklight displays a list of search results, it uses a Solr request 
  handler named "search." Thus, the field list (fl param) for the "search"
  request handler should be tailored to what will be displayed in a search
  results page.  Generally, this will not include fields containing a large
  quantity of text.  The facet param should contain the facets to be 
  displayed with the search results.
  ```xml

	<requestHandler name="search" class="solr.SearchHandler" >
		<lst name="defaults">
			<str name="defType">dismax</str>
			<str name="echoParams">explicit</str>
			<!-- list fields to be returned in the "fl" param -->
			<str name="fl">*,score</str>
			
			<str name="facet">on</str>
			<str name="facet.mincount">1</str>
			<str name="facet.limit">10</str>
			
			<!-- list fields to be displayed as facets here. -->
		    <str name="facet.field">format</str>
		    <str name="facet.field">language_facet</str>
			
			<str name="q.alt">*:*</str>
		</lst>
	</requestHandler>
   ```

#####Blacklight's "document" request handler:  for a single record

  When Blacklight displays a single record it uses a Solr request handler 
  named "document".  The "document" handler doesn't necessarily need to be 
  different than the "search" handler, but it can be used to control which 
  fields are available to display a single document. In the example below, 
  there is no faceting set (facets are not displayed with a single record) 
  and the "rows" param is set to 1 (since there will only be a single record).
  Also, the field list ("fl" param) could include fields containing large
  text values if they are desired for record display. Is is acceptable to
  include large amounts of data, because this handler should only be used 
  to query for one document:

	<requestHandler name="document" class="solr.SearchHandler">
		<lst name="defaults">
			<str name="echoParams">explicit</str>
			<str name="fl">*</str>
			<str name="rows">1</str>
			<str name="q">{!raw f=id v=$id}</str>
			<!-- use id=blah instead of q=id:blah -->
		</lst>
	</requestHandler>
	
  A Solr query for a single record might look like this:
   http://(yourSolrBaseUrl)/solr/select?id=my_doc_id&qt=document


####Blacklight Solr Schema and Solrconfig File Templates

Blacklight provides schema.xml and solrconfig.xml files as starting points:

  https://github.com/projectblacklight/blacklight-jetty/blob/master/solr/conf/schema.xml

  https://github.com/projectblacklight/blacklight-jetty/blob/master/solr/conf/solrconfig.xml

#SolrMARC:  from Marc data to Solr documents

The SolrMARC project is designed to create a Solr index from raw MARC data.  
It can be configured easily and used with the basic parsing and indexing 
supplied.  It is also readily customized for a site's unique requirements.

The project software and documentation is available at [[http://code.google.com/p/solrmarc]]

Blacklight comes with an embedded SolrMarc, with some default config that matches the default Blacklight setup, and provides some rake tasks to easily index docs with SolrMarc according to your app's environment.  There is no need to manually install/configure SolrMarc yourself.  From your application's home directory simply run:
```bash
  rake solr:marc:index:info
```
to see options.  Run `rake solr:marc:index` to actually do indexing. Like all rake tasks, by default this will use your 'development' environment; add "RAILS_ENV=production" to instead index to the solr you've labelled production in your config/solr.yml file. 

The solrmarc config files are in your app's config/SolrMarc directory, you can edit them there for local config. 

If you'd like to use a different or more recent version of SolrMarc.jar, you can put it in your app at ./solr_marc/SolrMarc.jar, and the built-in rake tasks will use your local SolrMarc.jar instead of the one bundled with Blacklight. 
