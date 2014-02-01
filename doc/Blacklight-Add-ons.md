## Stable Add-ons

A few add-ons are are more or less 'officially supported', and all Blacklight developers have commit rights on them. (although some may not have received attention in a while if developers have been busy. Feel free to ask on the list for current status):

* [Advanced search](https://github.com/projectblacklight/blacklight_advanced_search) plugin
* [CQL search](https://github.com/projectblacklight/blacklight_cql) plugin
* a fancy GUI [date range limit](https://github.com/projectblacklight/blacklight_range_limit) plugin.  



[RSolr Footnotes](https://github.com/cbeer/rsolr-footnotes) is useful for debugging, to see the request/response sent to Solr via RSolr: [[Integration with Rails Footnotes]]

(Not all 'stable' add-ons neccesarily need to be in Blacklight github areas; if others come to exist that the community deems stable, feel free to add them here.)


## Unstable/Experimental

* [[Blacklight Sitemap Generator|https://github.com/jronallo/blacklight-sitemap]]: Rake task for generating sitemaps.
* [[Blacklight Highlight|https://github.com/cbeer/blacklight_highlight]]: Expose Solr fulltext highlighting.
* [[Blacklight OAI provider|https://github.com/cbeer/blacklight_oai_provider]]: Adds an [[OAI-PMH|http://www.openarchives.org/pmh/]] provider using the [[oai|http://rubygems.org/gems/oai]] gem for harvesting records within Blacklight.
* [[Blacklight unAPI|https://github.com/cbeer/blacklight_unapi]]: Adds an [[unAPI|http://unapi.info]] endpoint for records within Blacklight.
* [[Blacklight User Generated Content|https://github.com/cbeer/blacklight_user_generated_content]]: Adds user generated content to SolrDocument objects using acts_as_commentable, acts_as_taggable and acts_as_rateable directly against a SolrDocument object. 
* [[Blacklight oEmbed|https://github.com/cbeer/blacklight_oembed]]: [[oEmbed|http://oembed.com]] endpoint that provides framework for allowing third-party sites (Wordpress, Facebook, etc) to embed content given a URL. 
* [[Blacklight More Like This|https://github.com/cbeer/blacklight_mlt]]: Solr more like this results
* [[Blacklight Google Analytics|https://github.com/jronallo/blacklight_google_analytics]]: Quick start for setting up Google Analytics for a Blacklight site, including Event Tracking of Blacklight-specific page elements like facets.

# Deprecated
* [[Blacklight Facet Extras|https://github.com/cbeer/blacklight_facet_extras]]: Exposes new faceting features present in Solr 3.1 and 3.4, such as facet queries, facet range requests, pivot facets, and tagged/excluded facets