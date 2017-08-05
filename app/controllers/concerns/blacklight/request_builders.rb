# frozen_string_literal: true
module Blacklight
  module RequestBuilders
    # Override this method to use a search builder other than the one in the config
    delegate :search_builder_class, to: :blacklight_config

    def search_builder
      search_builder_class.new(self)
    end

    ##
    # Opensearch autocomplete parameters for plucking a field's value from the results
    def solr_opensearch_params(field)
      solr_params = {}
      solr_params[:rows] ||= 10
      solr_params[:fl] = field || blacklight_config.view_config(:opensearch).title_field
      solr_params
    end

    ##
    # Pagination parameters for selecting the previous and next documents
    # out of a result set.
    def previous_and_next_document_params(index, window = 1)
      solr_params = blacklight_config.document_pagination_params.dup

      if solr_params.empty?
        solr_params[:fl] = blacklight_config.document_model.unique_key
      end

      if index > 0
        solr_params[:start] = index - window # get one before
        solr_params[:rows] = 2 * window + 1 # and one after
      else
        solr_params[:start] = 0 # there is no previous doc
        solr_params[:rows] = 2 * window # but there should be one after
      end

      solr_params[:facet] = false
      solr_params
    end
  end
end
