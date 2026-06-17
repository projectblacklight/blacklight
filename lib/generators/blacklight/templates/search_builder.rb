# frozen_string_literal: true
class <%= model_name.classify %> < Blacklight::SearchBuilder
  # Mixes in the behavior appropriate for the search index adapter configured
  # in config/blacklight.yml (Solr by default, or Elasticsearch).
  include Blacklight.search_builder_behavior

  ##
  # @example Adding a new step to the processor chain
  #   self.default_processor_chain += [:add_custom_data_to_query]
  #
  #   def add_custom_data_to_query(solr_parameters)
  #     solr_parameters[:custom] = blacklight_params[:user_value]
  #   end
end
