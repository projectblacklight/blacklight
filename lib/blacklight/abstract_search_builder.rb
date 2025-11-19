# frozen_string_literal: true

module Blacklight
  ##
  # Base class for all Blacklight search builders that converts Blacklight request
  # parameters into query parameters appropriate for search index. It does so by
  # evaluating a chain of processing methods to populate a result hash (see {#to_hash}).
  #
  # ## When to Use AbstractSearchBuilder
  #
  # You typically **should not use AbstractSearchBuilder directly**. Instead, use one of its subclasses:
  # - {Blacklight::SearchBuilder} for main search results
  # - {Blacklight::FacetSearchBuilder} for facet queries (e.g., "more facets" functionality)
  #
  # ## Creating Custom Search Builders
  #
  # You may extend AbstractSearchBuilder when creating specialized search builders that don't
  # fit the standard search results or facet patterns. Common use cases include:
  # - Building queries for specialized indexes or collections
  # - Creating search builders for administrative interfaces
  # - Implementing custom search workflows that require different processor chains
  #
  # ## Processor Chain Pattern
  #
  # All search builders use a "processor chain" pattern where methods are called in sequence
  # to build up the final query parameters. Each method in the chain receives a hash of
  # Solr parameters and can modify it:
  #
  #   class CustomSearchBuilder < AbstractSearchBuilder
  #     self.default_processor_chain = [:add_defaults, :add_custom_logic]
  #
  #     def add_defaults(solr_parameters)
  #       solr_parameters[:rows] = 20
  #     end
  #
  #     def add_custom_logic(solr_parameters)
  #       solr_parameters[:fq] ||= []
  #       solr_parameters[:fq] << 'status:active'
  #     end
  #   end
  #
  # Methods can be added to the processor chain by modifying `default_processor_chain`
  # or by using `append()` and `except()` methods on search builder instances.
  #
  # ## Important: Shared Query Logic Pattern
  #
  # When customizing search builders that modify core query parameters (`q` or `fq`),
  # you often need to apply the same logic to both SearchBuilder and FacetSearchBuilder
  # to ensure consistent behavior between search results and facet values.
  #
  #
  class AbstractSearchBuilder
    class_attribute :default_processor_chain
    self.default_processor_chain = []

    attr_reader :processor_chain, :search_state, :blacklight_params

    # @overload initialize(scope)
    #   @param [Object] scope scope the scope where the filter methods reside in.
    # @overload initialize(processor_chain, scope)
    #   @param [List<Symbol>,TrueClass] processor_chain options a list of filter methods to run or true, to use the default methods
    #   @param [Object] scope the scope where the filter methods reside in.
    def initialize(*options)
      case options.size
      when 1
        @processor_chain = default_processor_chain.dup
        @scope = options.first
      when 2
        @processor_chain, @scope = options
      else
        raise ArgumentError, "wrong number of arguments. (#{options.size} for 1..2)"
      end

      @blacklight_params = {}
      search_state_class = @scope.try(:search_state_class) || Blacklight::SearchState
      @search_state = search_state_class.new(@blacklight_params, @scope&.blacklight_config, @scope)
      @additional_filters = {}
      @merged_params = {}
      @reverse_merged_params = {}
    end

    delegate :blacklight_config, to: :scope

    ##
    # Set the parameters to pass through the processor chain
    def with(blacklight_params_or_search_state = {})
      params_will_change!
      @search_state = blacklight_params_or_search_state.is_a?(Blacklight::SearchState) ? blacklight_params_or_search_state : @search_state.reset(blacklight_params_or_search_state)
      @blacklight_params = @search_state.params.dup
      self
    end

    # sets the facet that this query pertains to, for the purpose of facet pagination
    def facet=(value)
      params_will_change!
      @facet = value
    end

    # @param [Object] value
    def facet(value = nil)
      if value
        self.facet = value
        return self
      end
      @facet
    end

    ##
    # Merge additional, repository-specific parameters
    def merge(extra_params, &)
      if extra_params
        params_will_change!
        @merged_params.merge!(extra_params.to_hash, &)
      end
      self
    end

    ##
    # "Reverse merge" additional, repository-specific parameters
    def reverse_merge(extra_params, &)
      if extra_params
        params_will_change!
        @reverse_merged_params.reverse_merge!(extra_params.to_hash, &)
      end
      self
    end

    delegate :[], :key?, to: :to_hash

    # a solr query method
    # @return [Blacklight::Solr::Response] the solr response object
    def to_hash
      return @params unless params_need_update?

      @params = processed_parameters
                .reverse_merge(@reverse_merged_params)
                .merge(@merged_params)
                .tap { clear_changes }
    end

    alias query to_hash
    alias to_h to_hash

    delegate :search_field, to: :search_state

    private

    attr_reader :scope

    def should_add_field_to_request? _field_name, field
      field.include_in_request || (field.include_in_request.nil? && blacklight_config.add_field_configuration_to_solr_request)
    end

    def request
      Blacklight::Solr::Request.new
    end

    # The CatalogController #index and #facet actions use this.
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
    #
    # @return a params hash for searching solr.
    def processed_parameters
      request.tap do |request_parameters|
        processor_chain.each do |method_name|
          send(method_name, request_parameters)
        end
      end
    end

    def params_will_change!
      @dirty = true
    end

    def params_changed?
      !!@dirty
    end

    def clear_changes
      @dirty = false
    end

    def params_need_update?
      params_changed? || @params.nil?
    end
  end
end
