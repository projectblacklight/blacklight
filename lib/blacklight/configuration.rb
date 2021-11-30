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
      autoload :NullDisplayField
      autoload :SearchField
      autoload :FacetField
      autoload :SortField
      autoload :DisplayField
      autoload :IndexField
      autoload :ShowField
    end

    include Fields

    # Set up Blacklight::Configuration.default_values to contain the basic, required Blacklight fields
    class << self
      # rubocop:disable Metrics/MethodLength
      def default_values
        @default_values ||= {
          # === Search request configuration
          # HTTP method to use when making requests to solr; valid
          # values are :get and :post.
          http_method: :get,
          # The path to send requests to solr.
          solr_path: 'select',
          # Default values of parameters to send with every search request
          default_solr_params: {},
          ##
          # === Single document request configuration
          # The solr request handler to use when requesting only a single document
          document_solr_request_handler: nil,
          # The path to send single document requests to solr
          document_solr_path: 'get',
          document_unique_id_param: :ids,
          # Default values of parameters to send when requesting a single document
          default_document_solr_params: {},
          fetch_many_document_params: {},
          document_pagination_params: {},
          ##
          # == Response models
          ## Class for sending and receiving requests from a search index
          repository_class: Blacklight::Solr::Repository,
          ## Class for converting Blacklight parameters to request parameters for the repository_class
          search_builder_class: ::SearchBuilder,
          # model that maps index responses to the blacklight response model
          response_model: Blacklight::Solr::Response,
          # the model to use for each response document
          document_model: ::SolrDocument,
          # the factory that builds document
          document_factory: Blacklight::DocumentFactory,
          # Class for paginating long lists of facet fields
          facet_paginator_class: Blacklight::Solr::FacetPaginator,
          # repository connection configuration
          connection_config: Blacklight.connection_config,
          ##
          # == Blacklight view configuration
          navbar: OpenStructWithHashAccess.new(partials: {}),
          # General configuration for all views
          index: ViewConfig::Index.new(
            # document presenter class used by helpers and views
            document_presenter_class: nil,
            # component class used to render a document
            document_component: Blacklight::DocumentComponent,
            # solr field to use to render a document title
            title_field: nil,
            # solr field to use to render format-specific partials
            display_type_field: nil,
            # partials to render for each document(see #render_document_partials)
            partials: [],
            document_actions: NestedOpenStructWithHashAccess.new(ToolConfig),
            collection_actions: NestedOpenStructWithHashAccess.new(ToolConfig),
            # what field, if any, to use to render grouped results
            group: false,
            # additional response formats for search results
            respond_to: OpenStructWithHashAccess.new
          ),
          # Additional configuration when displaying a single document
          show: ViewConfig::Show.new(
            # document presenter class used by helpers and views
            document_presenter_class: nil,
            document_component: Blacklight::DocumentComponent,
            display_type_field: nil,
            # Default route parameters for 'show' requests.
            # Set this to a hash with additional arguments to merge into the route,
            # or set `controller: :current` to route to the current controller.
            route: nil,
            # partials to render for each document(see #render_document_partials)
            partials: [],
            document_actions: NestedOpenStructWithHashAccess.new(ToolConfig)
          ),
          action_mapping: NestedOpenStructWithHashAccess.new(
            ViewConfig,
            default: { top_level_config: :index },
            show: { top_level_config: :show },
            citation: { parent_config: :show }
          ),
          # SMS and Email configurations.
          sms: ViewConfig.new,
          email: ViewConfig.new,
          # Configurations for specific types of index views
          view: NestedOpenStructWithHashAccess.new(ViewConfig,
                                                   list: {},
                                                   atom: {
                                                     if: false, # by default, atom should not show up as an alternative view
                                                     partials: [:document],
                                                     summary_component: Blacklight::DocumentComponent
                                                   },
                                                   rss: {
                                                     if: false, # by default, rss should not show up as an alternative view
                                                     partials: [:document]
                                                   }),
          #
          # These fields are created and managed below by `define_field_access`
          # facet_fields
          # index_fields
          # show_fields
          # sort_fields
          # search_fields
          ##
          # === Blacklight behavior configuration
          # Maxiumum number of spelling suggestions to offer
          spell_max: 5,
          # Maximum number of results to show per page
          max_per_page: 100,
          # Options for the user for number of results to show per page
          per_page: [10, 20, 50, 100],
          default_per_page: nil,
          # how many searches to save in session history
          search_history_window: 100,
          default_facet_limit: 10,
          default_more_limit: 20,
          # proc for determining whether the session is a crawler/bot
          # ex.: crawler_detector: lambda { |req| req.env['HTTP_USER_AGENT'] =~ /bot/ }
          crawler_detector: nil,
          autocomplete_suggester: 'mySuggester',
          raw_endpoint: OpenStructWithHashAccess.new(enabled: false),
          track_search_session: true,
          advanced_search: OpenStruct.new(enabled: false)
        }

        # rubocop:enable Metrics/MethodLength
      end
    end

    ##
    # Create collections of solr field configurations.
    # This will create array-like accessor methods for
    # the given field, and an #add_x_field convenience
    # method for adding new fields to the configuration

    # facet fields
    define_field_access :facet_field

    # solr fields to display on search results
    define_field_access :index_field

    # solr fields to display when showing single documents
    define_field_access :show_field

    # solr "fields" to use for scoping user search queries to particular fields
    define_field_access :search_field

    # solr fields to use for sorting results
    define_field_access :sort_field

    # solr fields to use in text message
    define_field_access :sms_field

    # solr fields to use in email message
    define_field_access :email_field

    def initialize(hash = {})
      super(self.class.default_values.deep_transform_values(&method(:_deep_copy)).merge(hash))
      yield(self) if block_given?

      @view_config ||= {}
    end

    def repository
      repository_class.new(self)
    end

    def default_per_page
      super || per_page.first
    end

    # DSL helper
    def configure
      yield self if block_given?
      self
    end

    # Returns default search field, used for simpler display in history, etc.
    # if not set, defaults to first defined search field
    def default_search_field
      @default_search_field ||= super || search_fields.values.find { |f| f.default == true } || search_fields.values.first
    end

    # Returns default sort field, used for simpler display in history, etc.
    # if not set, defaults to first defined sort field
    def default_sort_field
      field = super || sort_fields.values.find { |f| f.default == true }
      field || sort_fields.values.first
    end

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
      self.fields_for_type ||= {}

      (fields_for_type[display_type] ||= self.class.new).tap do |conf|
        yield(conf) if block_given?
      end
    end

    ##
    # Return a list of fields for the index display that should be used for the
    # provided document.  This respects any configuration made using for_display_type
    def index_fields_for(display_types)
      fields = {}.with_indifferent_access

      display_types.each do |display_type|
        fields = fields.merge(for_display_type(display_type).index_fields)
      end

      fields.merge(index_fields)
    end

    ##
    # Return a list of fields for the show page that should be used for the
    # provided document.  This respects any configuration made using for_display_type
    def show_fields_for(display_types)
      fields = {}.with_indifferent_access

      display_types.each do |display_type|
        fields = fields.merge(for_display_type(display_type).show_fields)
      end

      fields.merge(show_fields)
    end

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
