# frozen_string_literal: true
module Blacklight
  module RequestBuilders
    extend ActiveSupport::Concern

    included do
      if self.respond_to?(:helper_method)
        helper_method(:facet_limit_for)
      end
    end

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
      solr_params[:fl] = field || blacklight_config.view_config('opensearch').title_field
      solr_params
    end

    ##
    # Pagination parameters for selecting the previous and next documents
    # out of a result set.
    def previous_and_next_document_params(index, window = 1)
      solr_params = {}

      if index > 0
        solr_params[:start] = index - window # get one before
        solr_params[:rows] = 2*window + 1 # and one after
      else
        solr_params[:start] = 0 # there is no previous doc
        solr_params[:rows] = 2*window # but there should be one after
      end

      solr_params[:fl] = '*'
      solr_params[:facet] = false
      solr_params
    end
    
    DEFAULT_FACET_LIMIT = 10

    # Look up facet limit for given facet_field. Will look at config, and
    # if config is 'true' will look up from Solr @response if available. If
    # no limit is avaialble, returns nil. Used from #add_facetting_to_solr
    # to supply f.fieldname.facet.limit values in solr request (no @response
    # available), and used in display (with @response available) to create
    # a facet paginator with the right limit.
    def facet_limit_for(facet_field)
      facet = blacklight_config.facet_fields[facet_field]
      return if facet.blank?

      if facet.limit && @response && @response.aggregations[facet_field]
        limit = @response.aggregations[facet_field].limit

        if limit.nil? # we didn't get or a set a limit, so infer one.
          facet.limit if facet.limit != true
        elsif limit == -1 # limit -1 is solr-speak for unlimited
          nil
        else
          limit.to_i - 1 # we added 1 to find out if we needed to paginate
        end
      elsif facet.limit
        facet.limit == true ? DEFAULT_FACET_LIMIT : facet.limit
      end
    end
  end
end
