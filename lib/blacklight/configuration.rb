# frozen_string_literal: true

module Blacklight
  ##
  # Blacklight::Configuration holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Configuration < OpenStructWithHashAccess
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

    BASIC_SEARCH_PARAMETERS = [:q, :qt, :page, :per_page, :search_field, :sort, :controller, :action, :'facet.page', :'facet.prefix', :'facet.sort', :rows, :format, :view].freeze
    ADVANCED_SEARCH_PARAMETERS = [{ clause: {} }, :op].freeze

    # rubocop:disable Metrics/BlockLength
    default_configuration do
      property :logo_link, default: nil
      property :header_component, default: Blacklight::HeaderComponent
      property :full_width_layout, default: false

      # bootstrap_version may be set to 4 or 5
      bootstrap_version = ENV['BOOTSTRAP_VERSION'].presence || "5"
      property :bootstrap_version, default: /(\d)(?:\.\d){0,2}/.match(bootstrap_version)[1].to_i

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
      # @!attribute json_solr_path
      # @since v7.34.0
      # @return [String] The url path (relative to the solr base url) to use when using Solr's JSON Query DSL (as with the advanced search)
      property :json_solr_path, default: 'advanced'
      # @!attribute document_unique_id_param
      # @since v5.2.0
      # @return [Symbol] The solr query parameter used for sending the unique identifiers for one or more documents
      property :document_unique_id_param, default: :ids
      # @!attribute default_document_solr_params
      # @return [Hash] Default values of parameters to send with every single-document request
      property :default_document_solr_params, default: {}
      # @!attribute fetch_many_documents_path
      # @since v8.4.0
      # @return [String] The url path (relative to the solr base url) to use when requesting multiple documents by id
      property :fetch_many_documents_path, default: nil
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
      property :repository_class, default: Blacklight::Solr::Repository
      # @!attribute search_builder_class
      # @return [Class] class for converting Blacklight parameters to request parameters for the repository_class
      property :search_builder_class, default: ::SearchBuilder
      # @!attribute response_model
      # model that maps index responses to the blacklight response model
      # @return [Class]
      property :response_model, default: Blacklight::Solr::Response
      # @!attribute document_model
      # the model to use for each response document
      # @return [Class]
      property :document_model, default: ::SolrDocument
      # @!attribute document_factory
      # the factory that builds document
      # @return [Class]
      property :document_factory, default: Blacklight::DocumentFactory
      # @!attribute facet_paginator_class
      # Class for paginating long lists of facet fields
      # @return [Class]
      property :facet_paginator_class, default: Blacklight::Solr::FacetPaginator
      # @!attribute connection_config
      # repository connection configuration
      # @since v5.13.0
      # @return [Class]
      property :connection_config, default: Blacklight.connection_config

      ##
      # == Blacklight view configuration

      # @!attribute navbar
      # @since v5.8.0
      # @return [#partials]
      property :navbar, default: OpenStructWithHashAccess.new(partials: {})

      # @!attribute bookmark_icon_component
      # @since v8.3.1
      # component class used to render a document
      # set to Blacklight::Icons::BookmarkIconComponent to replace checkbox with icon
      property :bookmark_icon_component, default: nil

      # @!attribute index
      # General configuration for all views
      # @return [Blacklight::Configuration::ViewConfig::Index]
      property :index, default: ViewConfig::Index.new(
        # document presenter class used by helpers and views
        document_presenter_class: nil,
        # component class used to render a document
        document_component: Blacklight::DocumentComponent,
        sidebar_component: Blacklight::Search::SidebarComponent,
        # solr field to use to render a document title
        title_field: nil,
        # solr field to use to render format-specific partials
        display_type_field: nil,
        # the "field access" key to use to look up the document display fields
        document_fields_key: :index_fields,
        # partials to render for each document(see #render_document_partials)
        partials: [],
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
        search_bar_component: nil,
        # component class used to render the header above the documents
        search_header_component: Blacklight::SearchHeaderComponent,
        # pagination parameters to pass to kaminari
        pagination_options: Blacklight::Engine.config.blacklight.default_pagination_options.dup
      )

      # @!attribute show
      # Additional configuration when displaying a single document
      # @return [Blacklight::Configuration::ViewConfig::Show]
      property :show, default: ViewConfig::Show.new(
        # document presenter class used by helpers and views
        document_presenter_class: nil,
        document_component: Blacklight::DocumentComponent,
        # in Blacklight 9, the default show_tools_component configuration will
        # be Blacklight::Document::ShowToolsComponent
        show_tools_component: nil,
        sidebar_component: Blacklight::Document::SidebarComponent,
        display_type_field: nil,
        # the "field access" key to use to look up the document display fields
        document_fields_key: :show_fields,
        # Default route parameters for 'show' requests.
        # Set this to a hash with additional arguments to merge into the route,
        # or set `controller: :current` to route to the current controller.
        route: nil,
        # partials to render for each document(see #render_document_partials)
        partials: [],
        document_actions: NestedOpenStructWithHashAccess.new(ToolConfig)
      )

      # @!attribute action_mapping
      # @since v7.16.0
      # @return [Hash{Symbol => Blacklight::Configuration::ViewConfig}]
      property :action_mapping, default: NestedOpenStructWithHashAccess.new(
        ViewConfig,
        default: { top_level_config: :index },
        show: { top_level_config: :show },
        citation: { parent_config: :show },
        email_record: { top_level_config: :email },
        sms_record: { top_level_config: :sms }
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
                                                                    summary_component: Blacklight::DocumentComponent
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
      # { storage: false } value: do no tracking
      # @since v8.0.0
      # @return [Blacklight::Configuration::SessionTrackingConfig]
      property :track_search_session, default: Blacklight::Configuration::SessionTrackingConfig.new

      # @!attribute advanced_search
      # @since v7.15.0
      # @return [#enabled]
      property :advanced_search, default: OpenStruct.new(enabled: false)

      # @!attribute enable_search_bar_autofocus
      # @since v7.2.0
      # @return [Boolean]
      property :enable_search_bar_autofocus, default: false

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
      property :filter_search_state_fields, default: true

      # Additional Blacklight configuration setting for document-type specific
      # configuration.
      # @!attribute fields_for_type
      # @since v8.0.0
      # @return [Hash{Symbol => Blacklight::Configuration}]
      # @see [#for_display_type]
      property :fields_for_type, default: {}.with_indifferent_access
    end
    # rubocop:enable Metrics/BlockLength

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

      super(self.class.default_values.deep_transform_values(&method(:_deep_copy)).merge(hash))
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

    # @return [Integer]
    def default_per_page
      super || per_page.first
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
      @default_search_field ||= super || search_fields.values.find { |f| f.default == true } || search_fields.values.first
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
      deep_transform_values(&method(:_deep_copy))
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

      @view_config[[view_type, action_name]] ||= if view_type.nil?
                                                   action_config(action_name)
                                                 else
                                                   base_config = action_config(action_name)
                                                   base_config.merge(view.fetch(view_type, {}))
                                                 end
    end

    # YARD will include inline disabling as docs, cannot do multiline inside @!macro.  AND this must be separate from doc block.
    # rubocop:disable Layout/LineLength

    # Add a partial to the tools when rendering a document.
    # @!macro partial_if_unless
    #   @param name [String] the name of the document partial
    #   @param opts [Hash]
    #   @option opts [Class] :component draw a component
    #   @option opts [String] :partial partial to draw if component is false
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
      fields_for_type[display_type] ||= self.class.new

      fields_for_type[display_type].tap do |conf|
        yield(conf) if block_given?
      end
    end

    ##
    # Return a list of fields for the index display that should be used for the
    # provided document.  This respects any configuration made using for_display_type
    # @deprecated
    def index_fields_for(display_types)
      Array(display_types).inject(index_fields) do |fields, display_type|
        fields.merge(for_display_type(display_type).index_fields)
      end
    end

    ##
    # Return a list of fields for the show page that should be used for the
    # provided document.  This respects any configuration made using for_display_type
    # @deprecated
    def show_fields_for(display_types)
      Array(display_types).inject(show_fields) do |fields, display_type|
        fields.merge(for_display_type(display_type).show_fields)
      end
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
      when NestedOpenStructWithHashAccess then value.class.new(value.nested_class, value.to_h.deep_transform_values(&method(:_deep_copy)))
      when OpenStruct then value.class.new(value.to_h.deep_transform_values(&method(:_deep_copy)))
      else
        value.dup
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
