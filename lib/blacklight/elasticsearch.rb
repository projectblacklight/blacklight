# frozen_string_literal: true

module Blacklight
  module Elasticsearch
    autoload :Repository, "blacklight/elasticsearch/repository"
    autoload :Response, "blacklight/elasticsearch/response/facets"
    autoload :SearchBuilderBehavior, "blacklight/elasticsearch/search_builder_behavior"
  end
end
