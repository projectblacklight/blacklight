Blacklight will provide atom responses for all catalog/index results. Just add ".atom" on to the end of your path component, `/catalog.atom`, or `/catalog/index.atom`. 
```xml
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns="http://www.w3.org/2005/Atom">
  <title>Blacklight Search Results</title>
  <author>
    <name>Blacklight</name>
  </author>
  <link href="http://demo.projectblacklight.org/?commit=search&amp;amp;format=atom&amp;amp;q=urdu&amp;amp;search_field=all_fields" rel="self"/>
  <link href="http://demo.projectblacklight.org/?commit=search&amp;amp;format=html&amp;amp;q=urdu&amp;amp;search_field=all_fields" rel="alternate" type="text/html"/>
  <id>http://demo.projectblacklight.org/?commit=search&amp;amp;format=html&amp;amp;q=urdu&amp;amp;search_field=all_fields&amp;amp;type=text%2Fhtml</id>
  <link href="http://demo.projectblacklight.org/?commit=search&amp;amp;format=atom&amp;amp;page=2&amp;amp;q=urdu&amp;amp;search_field=all_fields" rel="next"/>
  <link href="http://demo.projectblacklight.org/?commit=search&amp;amp;format=atom&amp;amp;page=1&amp;amp;q=urdu&amp;amp;search_field=all_fields" rel="first"/>
  <link href="http://demo.projectblacklight.org/?commit=search&amp;amp;format=atom&amp;amp;page=15&amp;amp;q=urdu&amp;amp;search_field=all_fields" rel="last"/>
  <link href="http://demo.projectblacklight.org/catalog/opensearch.xml" rel="search" type="application/opensearchdescription+xml"/>
  <opensearch:totalResults>147</opensearch:totalResults>
  <opensearch:startIndex>0</opensearch:startIndex>
  <opensearch:itemsPerPage>10</opensearch:itemsPerPage>
  <opensearch:Query searchTerms="urdu" startPage="1" role="request"/>
  <updated>2011-05-11T17:46:58Z</updated>
  <entry>
    <title>Urdu&#772; d&#803;ra&#772;ma&#772;</title>
    <updated>2011-05-11T17:46:58Z</updated>
    <link href="http://demo.projectblacklight.org/catalog/2008306442" rel="alternate" type="text/html"/>
<link href="http://demo.projectblacklight.org/catalog/2008306442.dc_xml" rel="alternate" title="dc_xml" type="text/xml" />
<link href="http://demo.projectblacklight.org/catalog/2008306442.xml" rel="alternate" title="xml" type="application/xml" />
    <id>http://demo.projectblacklight.org/catalog/2008306442</id>
    <author>
      <name>Farg&#818;h&#818;a&#772;nah, 1979-</name>
    </author>
    <summary type="html">
&lt;dl class="defList"&gt;
  
      
        &lt;dt class="blacklight-title_display"&gt;Title:&lt;/dt&gt;
        &lt;dd class="blacklight-title_display"&gt;Urdu&#772; d&#803;ra&#772;ma&#772;&lt;/dd&gt;
                
        &lt;dt class="blacklight-author_display"&gt;Author:&lt;/dt&gt;
        &lt;dd class="blacklight-author_display"&gt;Farg&#818;h&#818;a&#772;nah, 1979-&lt;/dd&gt;
                
        
<!-- [...] -->
&lt;/dl&gt;
    </summary>
  </entry>
<!-- [...] -->
</feed>
```


The same HTML summary included in your HTML results pages are included as an `atom:summary` element -- the atom template uses the `[[#render_document_partial|https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight/blacklight_helper_behavior.rb#L203]]` helper method to generate this HTML summary, so if you've over-ridden that for your app, it will be used as the  `atom:summary` content instead.

## API Usage
The Atom response is intended to be pretty full of data, so it can fill many traditional API requests.  It makes use of every relevant atom or [[OpenSearch|http://www.opensearch.org/Home]] element that could be conveniently included. 

The Atom response also supports arbitrary format representations in the `atom:content` element.  You can include `&content_format=some_format` in your request URL (e.g. `[[/catalog.atom?content_format=oai_dc_xml|http://demo.projectblacklight.org/catalog.atom?q=urdu&content_format=oai_dc_xml]]`). Any format a given document can be exported as using the [[Blacklight document framework|Extending-blacklight-with-the-document-extension-framework]]  is available. Not every document can export in every format -- if a format is requested one or more of the items in your atom result can not export as, it will not have an `atom:content` element.  Non-XML-based formats are supported, as the content is Base64-encoded (as per Atom spec, unless the format is `text/plain`). 
```xml
<?xml version="1.0" encoding="UTF-8"?>
<feed xmlns:opensearch="http://a9.com/-/spec/opensearch/1.1/" xmlns="http://www.w3.org/2005/Atom">
  <title>Blacklight Search Results</title>
  <author>
    <name>Blacklight</name>
  </author>
  <link href="http://demo.projectblacklight.org/?content_format=oai_dc_xml&amp;amp;format=atom&amp;amp;per_page=1" rel="self"/>
<!-- [...] -->
  <entry>
    <title>The book of the dance in the 20th century selections from the Jane Bourne Parton collection of books on the dance</title>
    <updated>2011-05-11T17:59:32Z</updated>
    <link href="http://demo.projectblacklight.org/catalog/u1" rel="alternate" type="text/html"/>
<link href="http://demo.projectblacklight.org/catalog/u1.dc_xml" rel="alternate" title="dc_xml" type="text/xml" />
<link href="http://demo.projectblacklight.org/catalog/u1.xml" rel="alternate" title="xml" type="application/xml" />
    <id>http://demo.projectblacklight.org/catalog/u1</id>
    <author>
      <name>Roatcap, Adela Spindler</name>
    </author>
    <summary type="html">
<!-- [...] -->
    </summary>
<!-- [ Here is the export format as OAI Dublin Core XML ] -->
    <content type="text/xml">
<oai_dc:dc xsi:schemaLocation="http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd" xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"><dc:language>English</dc:language><dc:title>The book of the dance in the 20th century selections from the Jane Bourne Parton collection of books on the dance</dc:title><dc:format>Book</dc:format></oai_dc:dc>    </content>
  </entry>
</feed>
```

This means that if you add on a document extension that provides more export formats for some or all of your documents, that will automatically be available in the atom response. 

If you choose to use the [[Blacklight CQL add-on|https://github.com/projectblacklight/blacklight_cql]], the combination of [[CQL|http://www.loc.gov/standards/sru/specs/cql.html]]  requests and Atom responses provides a pretty good more-or-less standards-based API to search results through Blacklight. 

The Atom response generating template is at `app/views/catalog/index.builder.atom`.
