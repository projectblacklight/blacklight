module Blacklight
  ##
  # Blacklight::Configuration holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Configuration < OpenStructWithHashAccess

    require 'blacklight/configuration/view_config'
    require 'blacklight/configuration/tool_config'
    # XXX this isn't very pretty, but it works.
    require 'blacklight/configuration/fields'
    require 'blacklight/configuration/field'
    require 'blacklight/configuration/solr_field'
    require 'blacklight/configuration/search_field'
    require 'blacklight/configuration/facet_field'
    require 'blacklight/configuration/sort_field'
    include Fields
    extend Deprecation
    self.deprecation_horizon = 'blacklight 6.0'

    # Set up Blacklight::Configuration.default_values to contain
    # the basic, required Blacklight fields
    class << self
      def default_values

        @default_values ||= begin
          {
          ##
          # === Search request configuration
          ##
          # HTTP method to use when making requests to solr; valid
          # values are :get and :post.
          http_method: :get,
          # The solr request handler ('qt') to use for search requests
          qt: 'search',
          # The path to send requests to solr.
          solr_path: 'select',
          # Default values of parameters to send with every search request
          default_solr_params: {},
          ## deprecated; use add_facet_field :include_in_request instead;
          # if this is configured true, all facets will be included in the solr request
          # unless explicitly disabled.
          add_facet_fields_to_solr_request: false, 
          ## deprecated; use add_index_field :include_in_request instead;
          # if this is configured true, all show and index will be included in the solr request
          # unless explicitly disabled.
          add_field_configuration_to_solr_request: false,
          ##
          # === Single document request configuration
          ##
          # The solr rqeuest handler to use when requesting only a single document 
          document_solr_request_handler: 'document',
          # THe path to send single document requests to solr
          document_solr_path: nil,
          document_unique_id_param: :id,
          # Default values of parameters to send when requesting a single document
          default_document_solr_params: {
            ## Blacklight provides these settings in the /document request handler
            ## by default, we just ask for all fields. 
            #fl: '*',
            ## this is a fancy way to say "find the document by id using
            ## the value in the id query parameter"
            #q: "{!raw f=#{unique_key} v=$id}",
            ## disable features we don't need
            #facet: false,
            #rows: 1
          },
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
          # document presenter class used by helpers and views
          document_presenter_class: nil,
          # repository connection configuration
          connection_config: nil,
          ##
          # == Blacklight view configuration
          ##
          navbar: OpenStructWithHashAccess.new(partials: { }),
          # General configuration for all views
          index: ViewConfig::Index.new(
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
            respond_to: OpenStructWithHashAccess.new()
            ),
          # Additional configuration when displaying a single document
          show: ViewConfig::Show.new(
            # default route parameters for 'show' requests
            # set this to a hash with additional arguments to merge into 
            # the route, or set `controller: :current` to route to the 
            # current controller.
            route: nil,
            # partials to render for each document(see #render_document_partials) 
            partials: [:show_header, :show],
            document_actions: NestedOpenStructWithHashAccess.new(ToolConfig)
          ),
          # Configurations for specific types of index views
          view: NestedOpenStructWithHashAccess.new(ViewConfig,
            'list',
            atom: {
              if: false, # by default, atom should not show up as an alternative view
              partials: [:document]
            },
            rss: {
              if: false, # by default, rss should not show up as an alternative view
              partials: [:document]
          }),
          #
          # These fields are created and managed below by `defined_field_access`
          # facet_fields
          # index_fields
          # show_fields
          # sort_fields
          # search_fields
          ##
          # === Blacklight behavior configuration
          ##
          # Maxiumum number of spelling suggestions to offer
          spell_max: 5,
          # Maximum number of results to show per page
          max_per_page: 100,
          # Options for the user for number of results to show per page
          per_page: [10,20,50,100],
          default_per_page: nil,
          # how many searches to save in session history
          # (TODO: move the value into the configuration?)
          search_history_window: Blacklight::Catalog::SearchHistoryWindow,
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
    
    # solr "fields" to use for scoping user search queries
    # to particular fields
    define_field_access :search_field
    
    # solr fields to use for sorting results
    define_field_access :sort_field

    def initialize(*args)
      super(*args)
      initialize_default_values!
      yield(self) if block_given?
      self
    end

    ##
    # Initialize default values from the class attribute
    def initialize_default_values!
      Marshal.load(Marshal.dump(self.class.default_values)).each do |k, v|
        self[k] ||=  v
      end
    end

    def document_model
      super || ::SolrDocument
    end
    alias_method :solr_document_model, :document_model

    # only here to support alias_method
    def document_model= *args
      super
    end
    alias_method :solr_document_model=, :document_model=
    deprecation_deprecate solr_document_model: :document_model, :solr_document_model= => :document_model=

    def document_presenter_class
      super || Blacklight::DocumentPresenter
    end

    def response_model
      super || Blacklight::SolrResponse
    end
    alias_method :solr_response_model, :response_model
    # only here to support alias_method
    def response_model= *args
      super
    end
    alias_method :solr_response_model=, :response_model=
    deprecation_deprecate solr_response_model: :response_model, :solr_response_model= => :response_model=

    def repository_class
      super || Blacklight::SolrRepository
    end

    def connection_config
      super || Blacklight.connection_config
    end

    def search_builder_class
      super || locate_search_builder_class
    end

    def locate_search_builder_class
      ::SearchBuilder
    rescue NameError
      Deprecation.warn(Configuration, "Your application is missing the SearchBuilder. Have you run `rails generate blacklight:search_builder`? Falling back to Blacklight::Solr::SearchBuilder")
      Blacklight::Solr::SearchBuilder
    end

    def default_per_page
      super || per_page.first
    end

    ##
    # DSL helper
    def configure
      yield self if block_given?
      self
    end

    ##
    # Returns default search field, used for simpler display in history, etc.
    # if not set, defaults to first defined search field
    def default_search_field
      field = super
      field ||= search_fields.values.select { |field| field.default == true }.first
      field ||= search_fields.values.first

      field
    end

    ##
    # Returns default sort field, used for simpler display in history, etc.
    # if not set, defaults to first defined sort field
    def default_sort_field
      field = super
      field ||= sort_fields.values.select { |field| field.default == true }.first
      field ||= sort_fields.values.first

      field
    end
    
    def default_title_field
      document_model.unique_key || 'id'
    end

    ##
    # Add any configured facet fields to the default solr parameters hash
    # @overload add_facet_fields_to_solr_request!
    #    add all facet fields to the solr request
    # @overload add_facet_fields_to_solr_request! field, field, field
    #   @param [Symbol] Field names to add to the solr request
    #   @param [Symbol] 
    #   @param [Symbol] 
    def add_facet_fields_to_solr_request! *fields
      if fields.empty?
        self.add_facet_fields_to_solr_request = true
      else
        facet_fields.slice(*fields).each do |k,v|
          v.include_in_request = true
        end
      end
    end

    ##
    # Add any configured facet fields to the default solr parameters hash
    # @overload add_field_configuration_to_solr_request!
    #    add all index, show, and facet fields to the solr request
    # @overload add_field_configuration_to_solr_request! field, field, field
    #   @param [Symbol] Field names to add to the solr request
    #   @param [Symbol] 
    #   @param [Symbol] 
    def add_field_configuration_to_solr_request! *fields
      if fields.empty?
        self.add_field_configuration_to_solr_request = true
      else
        index_fields.slice(*fields).each do |k,v|
          v.include_in_request = true
        end

        show_fields.slice(*fields).each do |k,v|
          v.include_in_request = true
        end
        facet_fields.slice(*fields).each do |k,v|
          v.include_in_request = true
        end
      end
    end

    ##
    # Deprecated. Get the list of facet fields to explicitly
    # add to the solr request
    def facet_fields_to_add_to_solr
      facet_fields.select { |k,v| v.include_in_request }
                  .reject { |k,v| v[:query] || v[:pivot] }
                  .map { |k,v| v.field }
    end
    deprecation_deprecate :facet_fields_to_add_to_solr

    ##
    # Provide a 'deep copy' of Blacklight::Configuration that can be modifyed without affecting
    # the original Blacklight::Configuration instance.
    #
    # The Rails 3.x version only copies hashes, and ignores arrays and similar structures
    if ::Rails.version < "4.0"
      def deep_copy
        Marshal.load(Marshal.dump(self))
      end
      alias_method :inheritable_copy, :deep_copy
    else
      ##
      # Rails 4.x provides `#deep_dup`, but it aggressively `#dup`'s class names
      # too. These model names should not be `#dup`'ed or we might break ActiveModel::Naming.
      def deep_copy
        deep_dup.tap do |copy|
          copy.repository_class = self.repository_class
          copy.response_model = self.response_model
          copy.document_model = self.document_model
          copy.document_presenter_class = self.document_presenter_class
          copy.search_builder_class = self.search_builder_class
        end
      end
      alias_method :inheritable_copy, :deep_copy
    end

    ##
    # Get a view configuration for the given view type
    # including default values from the index configuration
    def view_config view_type
      if view_type == :show
        self.index.merge self.show
      else
        self.index.merge view.fetch(view_type, {})
      end
    end

    ##
    # Add a partial to the tools when rendering a document.
    # @param partial [String] the name of the document partial
    # @param opts [Hash]
    # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
    #                             The proc will receive the action configuration and the document or documents for the action.
    # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
    #                             The proc will receive the action configuration and the document or documents for the action.
    def add_show_tools_partial(name, opts = {})
      opts[:partial] ||= 'document_action'
      add_action(show.document_actions, name, opts)
    end

    ##
    # Add a tool for the search result list itself
    # @param partial [String] the name of the document partial
    # @param opts [Hash]
    # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
    #                             The proc will receive the action configuration and the document or documents for the action.
    # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
    #                             The proc will receive the action configuration and the document or documents for the action.
    def add_results_collection_tool(name, opts = {})
      add_action(index.collection_actions, name, opts)
    end

    ##
    # Add a partial to the tools for each document in the search results.
    # @param partial [String] the name of the document partial
    # @param opts [Hash]
    # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
    #                             The proc will receive the action configuration and the document or documents for the action.
    # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
    #                             The proc will receive the action configuration and the document or documents for the action.
    def add_results_document_tool(name, opts = {})
      add_action(index.document_actions, name, opts)
    end

    ##
    # Add a partial to the header navbar
    # @param partial [String] the name of the document partial
    # @param opts [Hash]
    # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
    #                             The proc will receive the action configuration and the document or documents for the action.
    # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
    #                             The proc will receive the action configuration and the document or documents for the action.
    def add_nav_action name, opts = {}
      add_action(navbar.partials, name, opts)
    end

    private

      def add_action config_hash, name, opts
        config = Blacklight::Configuration::ToolConfig.new opts
        config.name = name

        if block_given?
          yield config
        end

        config_hash[name] = config
      end
  end
end
