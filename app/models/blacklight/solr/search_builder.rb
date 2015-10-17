module Blacklight::Solr
  # @deprecated In 6.0 you should have this class generated into your application and Blacklight will
  #             no longer need to provide it.
  class SearchBuilder < Blacklight::SearchBuilder
    include Blacklight::Solr::SearchBuilderBehavior
  end
end
