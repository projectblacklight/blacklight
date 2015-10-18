module Blacklight
  ##
  # This module contains methods that are specified by SearchHelper.search_params_logic
  # They transform user parameters into parameters that are sent as a request to Solr when
  # RequestBuilders#solr_search_params is called.
  #
  module RequestBuilders
    extend ActiveSupport::Concern

    included do
      # We want to install a class-level place to keep
      # search_params_logic method names. Compare to before_filter,
      # similar design. Since we're a module, we have to add it in here.
      # There are too many different semantic choices in ruby 'class variables',
      # we choose this one for now, supplied by Rails.
      class_attribute :search_params_logic

      # Set defaults. Each symbol identifies a _method_ that must be in
      # this class, taking two parameters (solr_parameters, user_parameters)
      # Can be changed in local apps or by plugins, eg:
      # CatalogController.include ModuleDefiningNewMethod
      # CatalogController.search_params_logic += [:new_method]
      # CatalogController.search_params_logic.delete(:we_dont_want)
      self.search_params_logic = true

      if self.respond_to?(:helper_method)
        helper_method(:facet_limit_for)
      end
    end

    def search_builder_class
      blacklight_config.search_builder_class
    end

    def search_builder processor_chain = search_params_logic
      search_builder_class.new(processor_chain, self)
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

      if facet.limit and @response and @response.aggregations[facet_field]
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
