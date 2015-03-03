# -*- encoding : utf-8 -*-
module Blacklight::Solr
  
  autoload :Facets, 'blacklight/solr/facets'
  autoload :FacetPaginator, 'blacklight/solr/facet_paginator'
  autoload :Document, 'blacklight/solr/document'
  autoload :Request, 'blacklight/solr/request'
  autoload :SearchBuilder, 'blacklight/solr/search_builder'
  autoload :SearchBuilderBehavior, 'blacklight/solr/search_builder_behavior'
end
