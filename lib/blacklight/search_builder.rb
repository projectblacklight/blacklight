module Blacklight
  class SearchBuilder
    # @param [Hash,HashWithIndifferentAccess] user_params the user provided parameters (e.g. query, facets, sort, etc)
    # @param [List<Symbol>] processor_chain a list of filter methods to run
    # @param [Object] scope the scope where the filter methods reside in.
    def initialize(user_params, processor_chain, scope)
      @user_params = user_params
      @processor_chain = processor_chain
      @scope = scope
    end

    # a solr query method
    # @param [Hash,HashWithIndifferentAccess] extra_controller_params (nil) extra parameters to add to the search
    # @return [Blacklight::SolrResponse] the solr response object
    def query(extra_params = nil)
      extra_params ? processed_parameters.merge(extra_params) : processed_parameters
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
    def processed_parameters
      Blacklight::Solr::Request.new.tap do |request_parameters|
        @processor_chain.each do |method_name|
          @scope.send(method_name, request_parameters, @user_params)
        end
      end
    end

  end
end
