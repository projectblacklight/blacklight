# frozen_string_literal: true
module Blacklight
  ##
  # Blacklight's SearchBuilder converts blacklight request parameters into
  # query parameters appropriate for search index. It does so by evaluating a
  # chain of processing methods to populate a result hash (see {#to_hash}).
  class SearchBuilder
    class_attribute :default_processor_chain
    self.default_processor_chain = []

    attr_reader :processor_chain, :blacklight_params

    
    # @overload initialize(scope)
    #   @param [Object] scope scope the scope where the filter methods reside in.    
    # @overload initialize(processor_chain, scope)
    #   @param [List<Symbol>,TrueClass] processor_chain options a list of filter methods to run or true, to use the default methods
    #   @param [Object] scope scope the scope where the filter methods reside in.
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
      @merged_params = {}
      @reverse_merged_params = {}
    end

    ##
    # Set the parameters to pass through the processor chain
    def with(blacklight_params = {})
      params_will_change!
      @blacklight_params = blacklight_params.dup
      self
    end

    ##
    # Update the :q (query) parameter
    def where(conditions)
      params_will_change!
      @blacklight_params[:q] = conditions
      self
    end

    ##
    # Append additional processor chain directives
    def append(*addl_processor_chain)
      params_will_change!
      builder = self.class.new(processor_chain + addl_processor_chain, scope)
          .with(blacklight_params)
          .merge(@merged_params)
          .reverse_merge(@reverse_merged_params)

      builder.start = @start if @start
      builder.rows  = @rows if @rows
      builder.page  = @page if @page
      builder.facet = @facet if @facet
      builder
    end

    ##
    # Converse to append, remove processor chain directives,
    # returning a new builder that's a copy of receiver with
    # specified change.
    #
    # Methods in argument that aren't currently in processor
    # chain are ignored as no-ops, rather than raising.
    def except(*except_processor_chain)
      builder = self.class.new(processor_chain - except_processor_chain, scope)
          .with(blacklight_params)
          .merge(@merged_params)
          .reverse_merge(@reverse_merged_params)

      builder.start = @start if @start
      builder.rows  = @rows if @rows
      builder.page  = @page if @page
      builder.facet = @facet if @facet
      builder
    end

    ##
    # Merge additional, repository-specific parameters
    def merge(extra_params, &block)
      if extra_params
        params_will_change!
        @merged_params.merge!(extra_params.to_hash, &block)
      end
      self
    end

    ##
    # "Reverse merge" additional, repository-specific parameters
    def reverse_merge(extra_params, &block)
      if extra_params
        params_will_change!
        @reverse_merged_params.reverse_merge!(extra_params.to_hash, &block)
      end
      self
    end

    delegate :[], :key?, to: :to_hash

    # a solr query method
    # @return [Blacklight::Solr::Response] the solr response object
    def to_hash
      return @params unless params_need_update?
      @params = processed_parameters.
                  reverse_merge(@reverse_merged_params).
                  merge(@merged_params).
                  tap { self.clear_changes }
    end

    alias_method :query, :to_hash
    alias_method :to_h, :to_hash

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
    #
    # @return a params hash for searching solr.
    def processed_parameters
      request.tap do |request_parameters|
        processor_chain.each do |method_name|
          send(method_name, request_parameters)
        end
      end
    end

    delegate :blacklight_config, to: :scope

    def start=(value)
      params_will_change!
      @start = value.to_i
    end

    # @param [#to_i] value
    def start(value = nil)
      if value
        self.start = value
        return self
      end
      @start ||= (page - 1) * (rows || 10)
      val = @start || 0
      val = 0 if @start < 0
      val
    end
    alias_method :padding, :start

    def page=(value)
      params_will_change!
      @page = value.to_i
      @page = 1 if @page < 1
    end

    # @param [#to_i] value
    def page(value = nil)
      if value
        self.page = value
        return self
      end
      @page ||= blacklight_params[:page].blank? ? 1 : blacklight_params[:page].to_i
    end

    def rows=(value)
      params_will_change!
      @rows = [value, blacklight_config.max_per_page].map(&:to_i).min
    end

    # @param [#to_i] value
    def rows(value = nil)
      if value
        self.rows = value
        return self
      end
      @rows ||= begin
        # user-provided parameters should override any default row
        r = [:rows, :per_page].map {|k| blacklight_params[k] }.reject(&:blank?).first
        r ||= blacklight_config.default_per_page
        # ensure we don't excede the max page size
        r.nil? ? nil : [r, blacklight_config.max_per_page].map(&:to_i).min
      end
    end

    alias per rows

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

    def sort
      sort_field = if blacklight_params[:sort].blank?
        # no sort param provided, use default
        blacklight_config.default_sort_field
      else
        # check for sort field key
        blacklight_config.sort_fields[blacklight_params[:sort]]
      end

      field = if sort_field.present?
        sort_field.sort
      else
        # just pass the key through
        blacklight_params[:sort]
      end

      field unless field.blank?
    end

    def search_field
      blacklight_config.search_fields[blacklight_params[:search_field]]
    end

    protected

    def request
      Blacklight::Solr::Request.new
    end

    def should_add_field_to_request? _field_name, field
      field.include_in_request || (field.include_in_request.nil? && blacklight_config.add_field_configuration_to_solr_request)
    end

    attr_reader :scope

    def params_will_change!
      @dirty = true
    end

    def params_changed?
      !!@dirty
    end

    def params_need_update?
      params_changed? || @params.nil?
    end

    def clear_changes
      @dirty = false
    end
  end
end
