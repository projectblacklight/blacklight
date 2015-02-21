Blacklight's search, show and facets have JSON responses. The default serializations are very basic, but should be enough to drive simple AJAX widgets.

### Search results
`/catalog.json?search_field=all_fields&q=auckland`

```json
{
  "response":{
    "docs":[
      { "title_display":"Maine",
        "id":"2009002583",
        "author_display":"Dornfeld, Margaret",
        "format":"Book",
        "isbn_t":["9780761447269"],
        "published_display":["New York"],
        "lc_callnum_display":["F19.3 .D67 2011"],
        "subject_geo_facet":["Maine"],
        "pub_date":["2011"],
        "language_facet":["English"],
        "material_type_display":["p. cm"],
        "score":9.667667},
     {"title_display":"Ghostly lighthouses from Maine to Florida","id":"2005005219","author_display":"Monks, Sheryl, 1967-","format":"Book"},
        ...
       ],
    "pages": {  
      "current_page":1,
      "next_page":2,
      "prev_page":null,
      "total_pages":7,
      "limit_value":10,
      "offset_value":0,
      "total_count":61,
      "first_page?":true,
      "last_page?":false
    }
  }
}
```

### Facet list
`/catalog/facet/subject_topic_facet.json`

```json
{
  "response": {
    "facets": {
      "offset":0,
      "sort":"count",
      "items": [ 
         {"value":"Book","hits":9737}, 
         {"value":"Unknown","hits":88}
      ],
      "has_next":false,
      "has_previous":false,
      "limit":20
    }
  }
}
```

### Single record
`/catalog/2009002600.json`

```json
{
  "response":{
    "document":{
      "title_display":"Nebraska",
      "id":"2009002600",
      "author_display":"Bjorklund, Ruth",
       ....
     }
  }
}
```

The JSON serialization can be overridden in a local application by providing alternative implementations of:
  * `render_search_results_as_json`
  * `render_facet_list_as_json`

in your CatalogController.

See: https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/catalog.rb#L175-L191