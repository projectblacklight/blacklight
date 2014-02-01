Feature added in v4.5

By default the search page, the show page, and the facet list page can return JSON responses provided you set the format suffix:

Search results
`/catalog.json?search_field=all_fields&q=auckland`

Facet list
`/catalog/facet/subject_topic_facet.json`

Single record
`/catalog/2009002600.json`


If you wish to alter the format of the returned JSON, you can override `render_search_results_as_json` and `render_facet_list_as_json` methods in CatalogController.

See: https://github.com/projectblacklight/blacklight/blob/master/lib/blacklight/catalog.rb#L175-L191