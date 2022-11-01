# frozen_string_literal: true
module Blacklight
  ##
  # Blacklight::Configuration holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Configuration < OpenStructWithHashAccess
    extend ActiveSupport::Autoload
    eager_autoload do
      autoload :Context
      autoload :ViewConfig
      autoload :ToolConfig
      autoload :Fields
      autoload :Field
      autoload :NullField
      autoload :SearchField
      autoload :FacetField
      autoload :SortField
      autoload :DisplayField
      autoload :IndexField
      autoload :ShowField
    end

    class_attribute :default_values, default: {}

    # Set up Blacklight::Configuration.default_values to contain the basic, required Blacklight fields
    class << self
      def property(key, default: nil)
        default_values[key] = default
      end

      def default_configuration(&block)
        @default_configurations ||= []

        if block
          @default_configurations << block

          block.call if @default_configuration_initialized
        end

        @default_configurations
      end

      def initialize_default_configuration
        @default_configurations&.map(&:call)
        @default_configuration_initialized = true
      end

      def initialized_default_configuration?
        @default_configuration_initialized
      end
    end

    property :logo_link

    # === Search request configuration

    # @!attribute http_method
    # @since v5.0.0
    # @return [:get, :post] HTTP method used for search
    property :http_method, default: :get
    # @!attribute solr_path
    # @return [String] The path to send requests to solr.
    property :solr_path, default: 'select'
    # @!attribute default_solr_params
    # @return [Hash] Default values of parameters to send with every search request
    property :default_solr_params, default: {}

    # === Single document request configuration

    # @!attribute document_solr_request_handler
    # @return [String] The solr request handler to use when requesting only a single document
    property :document_solr_request_handler, default: nil
    # @!attribute document_solr_path
    # @since v5.2.0
    # @return [String] The url path (relative to the solr base url) to use when requesting only a single document
    property :document_solr_path, default: 'get'
    # @!attribute document_unique_id_param
    # @since v5.2.0
    # @return [Symbol] The solr query parameter used for sending the unique identifiers for one or more documents
    property :document_unique_id_param, default: :ids
    # @!attribute default_document_solr_params
    # @return [Hash] Default values of parameters to send with every single-document request
    property :default_document_solr_params, default: {}
    # @!attribute fetch_many_document_params
    # @since v7.0.0
    # @return [Hash] Default values of parameters to send with every multi-document request
    property :fetch_many_document_params, default: {}
    # @!attribute document_pagination_params
    # @return [Hash] Default values of parameters to send when getting the previous + next documents
    property :document_pagination_params, default: {}

    ##
    # == Response models

    # @!attribute repository_class
    # @return [Class] Class for sending and receiving requests from a search index
    property :repository_class, default: nil
    def repository_class
      super || Blacklight::Solr::Repository
    end

    # @!attribute search_builder_class
    # @return [Class] class for converting Blacklight parameters to request parameters for the repository_class
    property :search_builder_class, default: nil
    def search_builder_class
      super || locate_search_builder_class
    end

    def locate_search_builder_class
      ::SearchBuilder
    end

    # @!attribute response_model
    # model that maps index responses to the blacklight response model
    # @return [Class]
    property :response_model, default: nil
    def response_model
      super || Blacklight::Solr::Response
    end

    def response_model=(*args)
      super
    end

    # @!attribute document_factory
    # the factory that builds document
    # @return [Class]
    property :document_factory, default: nil
    # A class that builds documents
    def document_factory
      super || Blacklight::DocumentFactory
    end
    # @!attribute document_model
    # the model to use for each response document
    # @return [Class]
    property :document_model, default: nil
    def document_model
      super || ::SolrDocument
    end

    # only here to support alias_method
    def document_model=(*args)
      super
    end

    # @!attribute facet_paginator_class
    # Class for paginating long lists of facet fields
    # @return [Class]
    property :facet_paginator_class, default: nil
    def facet_paginator_class
      super || Blacklight::Solr::FacetPaginator
    end

    # @!attribute connection_config
    # repository connection configuration
    # @since v5.13.0
    # @return [Class]
    property :connection_config, default: nil
    def connection_config
      super || Blacklight.connection_config
    end

    ##
    # == Blacklight view configuration

    # @!attribute navbar
    # @since v5.8.0
    # @return [#partials]
    property :navbar, default: OpenStructWithHashAccess.new(partials: {})

    # @!attribute index
    # General configuration for all views
    # @return [Blacklight::Configuration::ViewConfig::Index]
    property :index, default: ViewConfig::Index.new(
      # document presenter class used by helpers and views
      document_presenter_class: nil,
      # component class used to render a document
      document_component: nil,
      # solr field to use to render a document title
      title_field: nil,
      # solr field to use to render format-specific partials
      display_type_field: nil,
      # partials to render for each document(see #render_document_partials)
      partials: [:index_header, :thumbnail, :index],
      document_actions: NestedOpenStructWithHashAccess.new(ToolConfig),
      collection_actions: NestedOpenStructWithHashAccess.new(ToolConfig),
      # what field, if any, to use to render grouped results
      group: false,
      # additional response formats for search results
      respond_to: OpenStructWithHashAccess.new,
      # component class used to render the facet grouping
      facet_group_component: nil,
      # component class used to render search constraints
      constraints_component: nil,
      # component class used to render the search bar
      search_bar_component: nil
    )

    # @!attribute show
    # Additional configuration when displaying a single document
    # @return [Blacklight::Configuration::ViewConfig::Show]
    property :show, default: ViewConfig::Show.new(
      # document presenter class used by helpers and views
      document_presenter_class: nil,
      document_component: nil,
      display_type_field: nil,
      # Default route parameters for 'show' requests.
      # Set this to a hash with additional arguments to merge into the route,
      # or set `controller: :current` to route to the current controller.
      route: nil,
      # partials to render for each document(see #render_document_partials)
      partials: [:show_header, :show],
      document_actions: NestedOpenStructWithHashAccess.new(ToolConfig)
    )

    # @!attribute action_mapping
    # @since v7.16.0
    # @return [Hash{Symbol => Blacklight::Configuration::ViewConfig}]
    property :action_mapping, default: NestedOpenStructWithHashAccess.new(
      ViewConfig,
      default: { top_level_config: :index },
      show: { top_level_config: :show },
      citation: { parent_config: :show }
    )

    # @!attribute sms
    # @since v7.21.0
    # @return [Blacklight::Configuration::ViewConfig]
    property :sms, default: ViewConfig.new

    # @!attribute email
    # @since v7.21.0
    # @return [Blacklight::Configuration::ViewConfig]
    property :email, default: ViewConfig.new

    # @!attribute
    # Configurations for specific types of index views
    # @return [Hash{Symbol => Blacklight::Configuration::ViewConfig}]
    property :view, default: NestedOpenStructWithHashAccess.new(ViewConfig,
                                                                list: {},
                                                                atom: {
                                                                  if: false, # by default, atom should not show up as an alternative view
                                                                  partials: [:document],
                                                                  summary_partials: [:index]
                                                                },
                                                                rss: {
                                                                  if: false, # by default, rss should not show up as an alternative view
                                                                  partials: [:document]
                                                                })

    ##
    # === Blacklight behavior configuration

    # @!attribute spell_max
    # Maxiumum number of spelling suggestions to offer
    # @return [Integer]
    property :spell_max, default: 5

    # @!attribute max_per_page
    # Maximum number of results to show per page
    # @return [Integer]
    property :max_per_page, default: 100
    # @!attribute per_page
    # Options for the user for number of results to show per page
    # @return [Array<Integer>]
    property :per_page, default: [10, 20, 50, 100]
    # @!attribute default_per_page
    # @return [Integer]
    property :default_per_page, default: nil
    # @return [Integer]
    def default_per_page
      super || per_page.first
    end

    # @!attribute search_history_window
    # how many searches to save in session history
    # @return [Integer]
    property :search_history_window, default: 100
    # @!attribute default_facet_limit
    # @since v5.10.0
    # @return [Integer]
    property :default_facet_limit, default: 10
    # @!attribute default_more_limit
    # @since v7.0.0
    # @return [Integer]
    property :default_more_limit, default: 20

    # @!attribute crawler_detector
    # proc for determining whether the session is a crawler/bot
    # ex.: crawler_detector: lambda { |req| req.env['HTTP_USER_AGENT'] =~ /bot/ }
    # @since v7.0.0
    # @return [<nil, Proc>]
    property :crawler_detector, default: nil

    # @!attribute autocomplete_suggester
    # @since v7.0.0
    # @return [String]
    property :autocomplete_suggester, default: 'mySuggester'

    # @!attribute raw_endpoint
    # @since v7.0.0
    # @return [#enabled]
    property :raw_endpoint, default: OpenStructWithHashAccess.new(enabled: false)

    # @!attribute track_search_session
    # @since v7.1.0
    # @return [Boolean]
    property :track_search_session, default: true

    # @!attribute advanced_search
    # @since v7.15.0
    # @return [#enabled]
    property :advanced_search, default: OpenStruct.new(enabled: false)

    # @!attribute enable_search_bar_autofocus
    # @since v7.2.0
    # @return [Boolean]
    property :enable_search_bar_autofocus, default: false

    BASIC_SEARCH_PARAMETERS = [:q, :qt, :page, :per_page, :search_field, :sort, :controller, :action, :'facet.page', :'facet.prefix', :'facet.sort', :rows, :format, :view].freeze
    ADVANCED_SEARCH_PARAMETERS = [{ clause: {} }, :op].freeze
    # List the request parameters that compose the SearchState.
    # If you use a plugin that adds to the search state, then you can add the parameters
    # by modifiying this field.
    # @!attribute search_state_fields
    # @since v8.0.0
    # @return [Array<Symbol>]
    property :search_state_fields, default: BASIC_SEARCH_PARAMETERS + ADVANCED_SEARCH_PARAMETERS

    # Have SearchState filter out unknown request parameters
    #
    # @!attribute filter_search_state_fields
    # @since v8.0.0
    # @return [Boolean]
    property :filter_search_state_fields, default: false

    ##
    # Create collections of solr field configurations.
    # This will create array-like accessor methods for
    # the given field, and an #add_x_field convenience
    # method for adding new fields to the configuration
    include Fields

    # facet fields
    # @!macro [attach] define_field_access
    #   @!attribute ${1}s
    #     @return [Hash{Symbol=>$2}]
    #   @!method add_${1}(config_key, hash_or_field_or_array)
    #     @param [Symbol] config_key
    #     @return [$2]
    #     @overload add_${1}(config_key, options)
    #       @param [Symbol] config_key
    #       @param [Hash] options
    #     @overload add_${1}(config_key, field)
    #       @param [Symbol] config_key
    #       @param [$2] field
    #     @overload add_${1}(config_key, array)
    #       @param [Symbol] config_key
    #       @param [Array<$2, Hash>] array
    #     @see #add_blacklight_field
    define_field_access :facet_field, Blacklight::Configuration::FacetField

    # solr fields to display on search results
    define_field_access :index_field, Blacklight::Configuration::IndexField

    # solr fields to display when showing single documents
    define_field_access :show_field, Blacklight::Configuration::ShowField

    # solr "fields" to use for scoping user search queries to particular fields
    define_field_access :search_field, Blacklight::Configuration::SearchField

    # solr fields to use for sorting results
    define_field_access :sort_field, Blacklight::Configuration::SortField

    # solr fields to use in text message
    define_field_access :sms_field, Blacklight::Configuration::DisplayField

    # solr fields to use in email message
    define_field_access :email_field, Blacklight::Configuration::DisplayField

    def initialize(hash = {})
      self.class.initialize_default_configuration unless self.class.initialized_default_configuration?

      super(self.class.default_values.deep_dup.merge(hash))
      yield(self) if block_given?

      @view_config ||= {}
    end

    # @return [Blacklight::Repository]
    def repository
      repository_class.new(self)
    end

    # @return [String] The destination for the link around the logo in the header
    def logo_link
      super || Rails.application.routes.url_helpers.root_path
    end

    # DSL helper
    # @yield [config]
    # @yieldparam [Blacklight::Configuration]
    # @return [Blacklight::Configuration]
    def configure
      yield self if block_given?
      self
    end

    # Returns default search field, used for simpler display in history, etc.
    # if not set, defaults to first defined search field
    # @return [Blacklight::Configuration::SearchField]
    def default_search_field
      field = super || search_fields.values.find { |f| f.default == true }
      field || search_fields.values.first
    end

    # Returns default sort field, used for simpler display in history, etc.
    # if not set, defaults to first defined sort field
    # @return [Blacklight::Configuration::SortField]
    def default_sort_field
      field = super || sort_fields.values.find { |f| f.default == true }
      field || sort_fields.values.first
    end

    # @return [String]
    def default_title_field
      document_model.unique_key || 'id'
    end

    # @param [String] field Solr facet name
    # @return [Blacklight::Configuration::FacetField] Blacklight facet configuration for the solr field
    def facet_configuration_for_field(field)
      # short-circuit on the common case, where the solr field name and the blacklight field name are the same.
      return facet_fields[field] if facet_fields[field] && facet_fields[field].field == field

      # Find the facet field configuration for the solr field, or provide a default.
      facet_fields.values.find { |v| v.field.to_s == field.to_s } ||
        FacetField.new(field: field).normalize!
    end

    # @param [String] group (nil) a group name of facet fields
    # @return [Array<String>] a list of the facet field names from the configuration
    def facet_field_names(group = nil)
      facet_fields_in_group(group).map(&:field)
    end

    # @param [String] group (nil) a group name of facet fields
    # @return [Array<Blacklight::Configuration::FacetField>] a list of facet fields
    def facet_fields_in_group(group)
      facet_fields.values.select { |opts| group == opts[:group] }
    end

    # @return [Array<String>] a list of facet groups
    def facet_group_names
      facet_fields.map { |_facet, opts| opts[:group] }.uniq
    end

    # Add any configured facet fields to the default solr parameters hash
    # @overload add_facet_fields_to_solr_request!
    #    add all facet fields to the solr request
    # @overload add_facet_fields_to_solr_request! field, field, etc
    #   @param [Symbol] field Field names to add to the solr request
    def add_facet_fields_to_solr_request!(*fields)
      if fields.empty?
        self.add_facet_fields_to_solr_request = true
      else
        facet_fields.slice(*fields).each_value { |v| v.include_in_request = true }
      end
    end

    # Add any configured facet fields to the default solr parameters hash
    # @overload add_field_configuration_to_solr_request!
    #    add all index, show, and facet fields to the solr request
    # @overload add_field_configuration_to_solr_request! field, field, etc
    #   @param [Symbol] field Field names to add to the solr request
    def add_field_configuration_to_solr_request!(*fields)
      if fields.empty?
        self.add_field_configuration_to_solr_request = true
      else
        index_fields.slice(*fields).each_value { |v| v.include_in_request = true }
        show_fields.slice(*fields).each_value { |v| v.include_in_request = true }
        facet_fields.slice(*fields).each_value { |v| v.include_in_request = true }
      end
    end

    # Provide a 'deep copy' of Blacklight::Configuration that can be modified without effecting
    # the original Blacklight::Configuration instance.
    #
    # Note: Rails provides `#deep_dup`, but it aggressively `#dup`'s class names too, turning them
    # into anonymous class instances.
    def deep_copy
      deep_transform_values_in_object(self, &method(:_deep_copy))
    end

    # builds a copy for the provided controller class
    # @param [Class] klass configuration host class
    def build(klass)
      deep_copy.tap do |conf|
        conf.klass = klass
      end
    end
    alias_method :inheritable_copy, :build

    # Get a view configuration for the given view type + action. The effective
    # view configuration is inherited from:
    # - the configuration from blacklight_config.view with the key `view_type`
    # - the configuration from blacklight_config.action_mapping with the key `action_name`
    # - any parent config for the action map result above
    # - the action_mapping default configuration
    # - the top-level index/show view configuration
    #
    # @param [Symbol,#to_sym] view_type
    # @return [Blacklight::Configuration::ViewConfig]
    def view_config(view_type = nil, action_name: :index)
      view_type &&= view_type.to_sym
      action_name &&= action_name.to_sym
      action_name ||= :index

      if view_type == :show
        action_name = view_type
        view_type = nil
      end

      @view_config[[view_type, action_name]] ||= begin
        if view_type.nil?
          action_config(action_name)
        else
          base_config = action_config(action_name)
          base_config.merge(view.fetch(view_type, {}))
        end
      end
    end

    # YARD will include inline disabling as docs, cannot do multiline inside @!macro.  AND this must be separate from doc block.
    # rubocop:disable Layout/LineLength

    # Add a partial to the tools when rendering a document.
    # @!macro partial_if_unless
    #   @param name [String] the name of the document partial
    #   @param opts [Hash]
    #   @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true. The proc will receive the action configuration and the document or documents for the action.
    #   @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true. The proc will receive the action configuration and the document or documents for the action.
    def add_show_tools_partial(name, opts = {})
      opts[:partial] ||= 'document_action'
      add_action(show.document_actions, name, opts)
      klass && ActionBuilder.new(klass, name, opts).build
    end
    # rubocop:enable Layout/LineLength

    # Add a tool for the search result list itself
    # @!macro partial_if_unless
    def add_results_collection_tool(name, opts = {})
      add_action(index.collection_actions, name, opts)
    end

    # Add a partial to the tools for each document in the search results.
    # @!macro partial_if_unless
    def add_results_document_tool(name, opts = {})
      add_action(index.document_actions, name, opts)
    end

    # Add a partial to the header navbar
    # @!macro partial_if_unless
    def add_nav_action(name, opts = {})
      add_action(navbar.partials, name, opts)
    end

    ##
    # Add a section of config that only applies to documents with a matching display type
    def for_display_type display_type, &_block
      self.fields_for_type ||= {}

      (fields_for_type[display_type] ||= self.class.new).tap do |conf|
        yield(conf) if block_given?
      end
    end

    ##
    # Return a list of fields for the index display that should be used for the
    # provided document.  This respects any configuration made using for_display_type
    def index_fields_for(document_or_display_types)
      display_types = if document_or_display_types.is_a? Blacklight::Document
                        Deprecation.warn self, "Calling index_fields_for with a #{document_or_display_types.class} is deprecated and will be removed in Blacklight 8. Pass the display type instead."
                        document_or_display_types[index.display_type_field || 'format']
                      else
                        document_or_display_types
                      end

      fields = {}.with_indifferent_access

      Array.wrap(display_types).each do |display_type|
        fields = fields.merge(for_display_type(display_type).index_fields)
      end

      fields.merge(index_fields)
    end

    ##
    # Return a list of fields for the show page that should be used for the
    # provided document.  This respects any configuration made using for_display_type
    def show_fields_for(document_or_display_types)
      display_types = if document_or_display_types.is_a? Blacklight::Document
                        Deprecation.warn self, "Calling show_fields_for with a #{document_or_display_types.class} is deprecated and will be removed in Blacklight 8. Pass the display type instead."
                        document_or_display_types[show.display_type_field || 'format']
                      else
                        document_or_display_types
                      end

      unless display_types.respond_to?(:each)
        Deprecation.warn self, "Calling show_fields_for with a scalar value is deprecated. It must receive an Enumerable."
        display_types = Array.wrap(display_types)
      end
      fields = {}.with_indifferent_access

      display_types.each do |display_type|
        fields = fields.merge(for_display_type(display_type).show_fields)
      end

      fields.merge(show_fields)
    end

    # @!visibility private
    def freeze
      each { |_k, v| v.is_a?(OpenStruct) && v.freeze }
      super
    end

    private

    def add_action(config_hash, name, opts)
      config = Blacklight::Configuration::ToolConfig.new opts
      config.name ||= name
      config.key = name
      yield(config) if block_given?
      config_hash[name] = config
    end

    # Provide custom duplication for certain types of configuration (intended for use in e.g. deep_transform_values)
    def _deep_copy(value)
      case value
      when Module then value
      when NestedOpenStructWithHashAccess then value.class.new(value.nested_class, deep_transform_values_in_object(value.to_h, &method(:_deep_copy)))
      when OpenStruct then value.class.new(deep_transform_values_in_object(value.to_h, &method(:_deep_copy)))
      else
        value.dup
      end
    end

    # This is a little shim to support Rails 6 (which has Hash#deep_transform_values) and
    # earlier versions (which use our backport). Once we drop support for Rails 6, this
    # can go away.
    def deep_transform_values_in_object(object, &block)
      return object.deep_transform_values(&block) if object.respond_to?(:deep_transform_values)

      _deep_transform_values_in_object(object, &block)
    end

    # Ported from Rails 6
    def _deep_transform_values_in_object(object, &block)
      case object
      when Hash
        object.transform_values { |value| _deep_transform_values_in_object(value, &block) }
      when Array
        object.map { |e| _deep_transform_values_in_object(e, &block) }
      else
        yield(object)
      end
    end

    def action_config(action, default: :index)
      action_config = action_mapping[action]
      action_config ||= action_mapping[:default]

      if action_config.parent_config && action_config.parent_config != :default
        parent_config = action_mapping[action_config.parent_config]
        raise "View configuration error: the parent configuration of #{action_config.key}, #{parent_config.key}, must not specific its own parent configuration" if parent_config.parent_config

        action_config = action_config.reverse_merge(parent_config)
      end
      action_config = action_config.reverse_merge(action_mapping[:default]) if action_config != action_mapping[:default]

      action_config = action_config.reverse_merge(self[action_config.top_level_config]) if action_config.top_level_config
      action_config = action_config.reverse_merge(show) if default == :show && action_config.top_level_config != :show
      action_config.reverse_merge(index)
    end
  end
end
