# frozen_string_literal: true
module Blacklight
  module Solr
    autoload :Document, 'blacklight/solr/document'
    autoload :FacetPaginator, 'blacklight/solr/facet_paginator'
    autoload :Repository, 'blacklight/solr/repository'
    autoload :Request, 'blacklight/solr/request'
    autoload :Response, 'blacklight/solr/response'
    autoload :SearchBuilderBehavior, 'blacklight/solr/search_builder_behavior'
  end
end
