# frozen_string_literal: true

class FacetSearchBuilder < Blacklight::FacetSearchBuilder
  include Blacklight::Solr::FacetSearchBuilderBehavior
end
