module Blacklight
  module SolrHelper
    extend ActiveSupport::Concern
    included do
      include Blacklight::SearchHelper
      Deprecation.warn Blacklight::SolrHelper, "Blacklight::SolrHelper is deprecated; use Blacklight::SearchHelper instead"
    end
  end
end
