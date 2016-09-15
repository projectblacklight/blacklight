# frozen_string_literal: true
class <%= model_name.classify %> < Blacklight::SearchBuilder
  include Blacklight::Solr::SearchBuilderBehavior
end
