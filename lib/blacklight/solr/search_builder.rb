module Blacklight::Solr
  # @deprecated
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
  end
end
