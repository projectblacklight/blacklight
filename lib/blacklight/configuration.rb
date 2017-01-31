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
    end

    include Fields

    # Set up Blacklight::Configuration.default_values to contain the basic, required Blacklight fields
    class << self
      def default_values
        @default_values ||= begin
          {
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
          # The solr rqeuest handler to use when requesting only a single document
          document_solr_request_handler: nil,
          # The path to send single document requests to solr
          document_solr_path: 'get',
          document_unique_id_param: :ids,
          # Default values of parameters to send when requesting a single document
          default_document_solr_params: {},
          ##
          # == Response models
          ## Class for sending and receiving requests from a search index
          repository_class: nil,
          ## Class for converting Blacklight parameters to request parameters for the repository_class
          search_builder_class: nil,
          # model that maps index responses to the blacklight response model
          response_model: nil,
          # the model to use for each response document
          document_model: nil,
          # Class for paginating long lists of facet fields
          facet_paginator_class: nil,
          # repository connection configuration
          connection_config: nil,
          ##
          # == Blacklight view configuration
          navbar: OpenStructWithHashAccess.new(partials: {}),
          # General configuration for all views
          index: ViewConfig::Index.new(
            # document presenter class used by helpers and views
            document_presenter_class: nil,
            # solr field to use to render a document title
            title_field: nil,
            # solr field to use to render format-specific partials
            display_type_field: 'format',
            # partials to render for each document(see #render_document_partials)
            partials: [:index_header, :thumbnail, :index],
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
            # Default route parameters for 'show' requests.
            # Set this to a hash with additional arguments to merge into the route,
            # or set `controller: :current` to route to the current controller.
            route: nil,
            # partials to render for each document(see #render_document_partials)
            partials: [:show_header, :show],
            document_actions: NestedOpenStructWithHashAccess.new(ToolConfig)
          ),
          # Configurations for specific types of index views
          view: NestedOpenStructWithHashAccess.new(ViewConfig,
                                                   list: {},
                                                   atom: {
                                                     if: false, # by default, atom should not show up as an alternative view
                                                     partials: [:document]
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
          default_facet_limit: 10
          }
        end
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

    def initialize(hash = {})
      super(self.class.default_values.deep_dup.merge(hash))
      yield(self) if block_given?
    end

    def document_model
      super || ::SolrDocument
    end

    # only here to support alias_method
    def document_model=(*args)
      super
    end

    def response_model
      super || Blacklight::Solr::Response
    end

    def response_model=(*args)
      super
    end

    def repository_class
      super || Blacklight::Solr::Repository
    end

    def repository
      repository_class.new(self)
    end

    def connection_config
      super || Blacklight.connection_config
    end

    def search_builder_class
      super || locate_search_builder_class
    end

    def locate_search_builder_class
      ::SearchBuilder
    end

    def facet_paginator_class
      super || Blacklight::Solr::FacetPaginator
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
      field = super || search_fields.values.find { |f| f.default == true }
      field || search_fields.values.first
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

    # Add any configured facet fields to the default solr parameters hash
    # @overload add_facet_fields_to_solr_request!
    #    add all facet fields to the solr request
    # @overload add_facet_fields_to_solr_request! field, field, etc
    #   @param [Symbol] field Field names to add to the solr request
    def add_facet_fields_to_solr_request!(*fields)
      if fields.empty?
        self.add_facet_fields_to_solr_request = true
      else
        facet_fields.slice(*fields).each { |_k, v| v.include_in_request = true }
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
        index_fields.slice(*fields).each { |_k, v| v.include_in_request = true }
        show_fields.slice(*fields).each { |_k, v| v.include_in_request = true }
        facet_fields.slice(*fields).each { |_k, v| v.include_in_request = true }
      end
    end

    # Provide a 'deep copy' of Blacklight::Configuration that can be modified without effecting
    # the original Blacklight::Configuration instance.
    #
    # Rails 4.x provides `#deep_dup`, but it aggressively `#dup`'s class names
    # too. These model names should not be `#dup`'ed or we might break ActiveModel::Naming.
    def deep_copy
      deep_dup.tap do |copy|
        %w(repository_class response_model document_model document_presenter_class search_builder_class facet_paginator_class).each do |klass|
          # Don't copy if nil, so as not to prematurely autoload default classes
          copy.send("#{klass}=", send(klass)) unless fetch(klass.to_sym, nil).nil?
        end
      end
    end
    alias_method :inheritable_copy, :deep_copy

    # Get a view configuration for the given view type
    # including default values from the index configuration
    # @param [Symbol,#to_sym] view_type
    def view_config(view_type)
      view_type = view_type.to_sym unless view_type.is_a? Symbol
      index.merge(view_type == :show ? show : view.fetch(view_type, {}))
    end

    # YARD will include inline disabling as docs, cannot do multiline inside @!macro.  AND this must be separate from doc block.
    # rubocop:disable Metrics/LineLength

    # Add a partial to the tools when rendering a document.
    # @!macro partial_if_unless
    #   @param name [String] the name of the document partial
    #   @param opts [Hash]
    #   @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true. The proc will receive the action configuration and the document or documents for the action.
    #   @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true. The proc will receive the action configuration and the document or documents for the action.
    def add_show_tools_partial(name, opts = {})
      opts[:partial] ||= 'document_action'
      add_action(show.document_actions, name, opts)
    end
    # rubocop:enable Metrics/LineLength

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

    private

      def add_action(config_hash, name, opts)
        config = Blacklight::Configuration::ToolConfig.new opts
        config.name = name
        yield(config) if block_given?
        config_hash[name] = config
      end
  end
end
