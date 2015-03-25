# frozen_string_literal: true
class <%= model_name.classify %> < Blacklight::SearchBuilder
  # include Blacklight::Solr::SearchBuilderBehavior
  include Blacklight::Elasticsearch::SearchBuilderBehavior

  ##
  # @example Adding a new step to the processor chain
  #   self.default_processor_chain += [:add_custom_data_to_query]
  #
  #   def add_custom_data_to_query(solr_parameters)
  #     solr_parameters[:custom] = blacklight_params[:user_value]
  #   end
end
