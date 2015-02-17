module Blacklight
  ##
  # This module contains methods that are specified by SearchHelper.search_params_logic
  # They transform user parameters into parameters that are sent as a request to Solr when
  # RequestBuilders#solr_search_params is called.
  #
  module RequestBuilders
    extend ActiveSupport::Concern
    extend Deprecation
    self.deprecation_horizon = 'blacklight 6.0'

    included do
      # We want to install a class-level place to keep
      # search_params_logic method names. Compare to before_filter,
      # similar design. Since we're a module, we have to add it in here.
      # There are too many different semantic choices in ruby 'class variables',
      # we choose this one for now, supplied by Rails.
      class_attribute :search_params_logic

      alias_method :solr_search_params_logic, :search_params_logic
      deprecation_deprecate :solr_search_params_logic

      alias_method :solr_search_params_logic=, :search_params_logic=
      deprecation_deprecate :solr_search_params_logic=

      # Set defaults. Each symbol identifies a _method_ that must be in
      # this class, taking two parameters (solr_parameters, user_parameters)
      # Can be changed in local apps or by plugins, eg:
      # CatalogController.include ModuleDefiningNewMethod
      # CatalogController.search_params_logic += [:new_method]
      # CatalogController.search_params_logic.delete(:we_dont_want)
      self.search_params_logic = [:default_solr_parameters, :add_query_to_solr, :add_facet_fq_to_solr, :add_facetting_to_solr, :add_solr_fields_to_query, :add_paging_to_solr, :add_sorting_to_solr, :add_group_config_to_solr ]

      if self.respond_to?(:helper_method)
        helper_method(:facet_limit_for)
      end
    end

    module ClassMethods
      extend Deprecation
      self.deprecation_horizon = 'blacklight 6.0'

      def solr_search_params_logic
        search_params_logic
      end
      deprecation_deprecate :solr_search_params_logic

      def solr_search_params_logic= logic
        self.search_params_logic= logic
      end
      deprecation_deprecate :solr_search_params_logic=
    end

    def search_builder_class
      Blacklight::Solr::SearchBuilder
    end

    def search_builder processor_chain = search_params_logic
      search_builder_class.new(processor_chain, self)
    end


    # @returns a params hash for searching solr.
    # The CatalogController #index action uses this.
    # Solr parameters can come from a number of places. From lowest
    # precedence to highest:
    #  1. General defaults in blacklight config (are trumped by)
    #  2. defaults for the particular search field identified by  params[:search_field] (are trumped by) 
    #  3. certain parameters directly on input HTTP query params 
    #     * not just any parameter is grabbed willy nilly, only certain ones are allowed by HTTP input)
    #     * for legacy reasons, qt in http query does not over-ride qt in search field definition default. 
    #  4.  extra parameters passed in as argument.
    #
    # spellcheck.q will be supplied with the [:q] value unless specifically
    # specified otherwise. 
    #
    # Incoming parameter :f is mapped to :fq solr parameter.
    def solr_search_params(user_params = params || {}, processor_chain = search_params_logic)
      Deprecation.warn(RequestBuilders, "solr_search_params is deprecated and will be removed in blacklight-6.0. Use SearchBuilder#processed_parameters instead.")
      search_builder(processor_chain).with(user_params).processed_parameters
    end

    ##
    # @param [Hash] user_params a hash of user submitted parameters
    # @param [Array] processor_chain a list of processor methods to run
    # @param [Hash] extra_params an optional hash of parameters that should be
    #                            added to the query post processing
    def build_solr_query(user_params, processor_chain, extra_params=nil)
      Deprecation.warn(RequestBuilders, "build_solr_query is deprecated and will be removed in blacklight-6.0. Use SearchBuilder#query instead")
      search_builder(processor_chain).with(user_params).query(extra_params)
    end

    ##
    # Retrieve the results for a list of document ids
    def solr_document_ids_params(ids = [])
      Deprecation.silence(Blacklight::RequestBuilders) do
        solr_documents_by_field_values_params blacklight_config.document_model.unique_key, ids
      end
    end

    ##
    # Retrieve the results for a list of document ids
    # @deprecated
    def solr_documents_by_field_values_params(field, values)
      search_builder([:add_query_to_solr]).with(q: { field => values}).query(fl: '*')
    end
    deprecation_deprecate :solr_documents_by_field_values_params

    ##
    # Retrieve a facet's paginated values.
    def solr_facet_params(facet_field, user_params=params || {}, extra_controller_params={})
      input = user_params.deep_merge(extra_controller_params)
      facet_config = blacklight_config.facet_fields[facet_field]

      solr_params = {}

      # Now override with our specific things for fetching facet values
      solr_params[:"facet.field"] = search_builder.with_ex_local_param((facet_config.ex if facet_config.respond_to?(:ex)), facet_field)

      limit = if respond_to?(:facet_list_limit)
          facet_list_limit.to_s.to_i
        elsif solr_params["facet.limit"]
          solr_params["facet.limit"].to_i
        else
          20
        end

      # Need to set as f.facet_field.facet.* to make sure we
      # override any field-specific default in the solr request handler.
      solr_params[:"f.#{facet_field}.facet.limit"]  = limit + 1
      solr_params[:"f.#{facet_field}.facet.offset"] = ( input.fetch(Blacklight::Solr::FacetPaginator.request_keys[:page] , 1).to_i - 1 ) * ( limit )
      solr_params[:"f.#{facet_field}.facet.sort"] = input[  Blacklight::Solr::FacetPaginator.request_keys[:sort] ] if  input[  Blacklight::Solr::FacetPaginator.request_keys[:sort] ]
      solr_params[:rows] = 0

      solr_params
    end

    ##
    # Opensearch autocomplete parameters for plucking a field's value from the results
    def solr_opensearch_params(field=nil)
      if field.nil?
        Deprecation.warn(Blacklight::RequestBuilders, "Calling Blacklight::RequestBuilders#solr_opensearch_params without a field name is deprecated and will be required in Blacklight 6.0.")
      end

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

      if facet.limit and @response and @response.facet_by_field_name(facet_field)
        limit = @response.facet_by_field_name(facet_field).limit

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
