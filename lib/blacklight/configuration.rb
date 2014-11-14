module Blacklight
  ##
  # Blacklight::Configuration holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Configuration < OpenStructWithHashAccess

    require 'blacklight/configuration/view_config'
    require 'blacklight/configuration/tool_config'
    # XXX this isn't very pretty, but it works.
    require 'blacklight/configuration/fields'
    require 'blacklight/configuration/solr_field'
    require 'blacklight/configuration/search_field'
    require 'blacklight/configuration/facet_field'
    require 'blacklight/configuration/sort_field'
    include Fields

    # Set up Blacklight::Configuration.default_values to contain
    # the basic, required Blacklight fields
    class << self
      def default_values

        @default_values ||= begin
          {
          # HTTP method to use when making requests to solr; valid
          # values are :get and :post.
          :http_method => :get,
          # The solr request handler ('qt') to use for search requests
          :qt => 'search',
          # The path to send requests to solr.
          :solr_path => 'select',
          # Default values of parameters to send with every search request
          :default_solr_params => {},
          # the model to load solr response documents into; set below in #initialize_default_values
          :solr_document_model => nil,
          # The solr rqeuest handler to use when requesting only a single document 
          :document_solr_request_handler => 'document',
          # THe path to send single document requests to solr
          :document_solr_path => nil,
          :document_unique_id_param => :id,
          # Default values of parameters to send when requesting a single document
          :default_document_solr_params => {
            ## Blacklight provides these settings in the /document request handler
            ## by default, we just ask for all fields. 
            #:fl => '*',
            ## this is a fancy way to say "find the document by id using
            ## the value in the id query parameter"
            #:q => "{!raw f=#{unique_key} v=$id}",
            ## disable features we don't need
            #:facet => false,
            #:rows => 1
          },
          # General configuration for all views
          :index => ViewConfig::Index.new(
            # solr field to use to render a document title
            :title_field => nil,
            # solr field to use to render format-specific partials
            :display_type_field => 'format',
            # partials to render for each document(see #render_document_partials)
            :partials => [:index_header, :thumbnail, :index],
            # what field, if any, to use to render grouped results
            :group => false,
            # additional response formats for search results
            :respond_to => OpenStructWithHashAccess.new()
            ),
          # Additional configuration when displaying a single document
          :show => ViewConfig::Show.new(
            # default route parameters for 'show' requests
            # set this to a hash with additional arguments to merge into 
            # the route, or set `controller: :current` to route to the 
            # current controller.
            route: nil,
            # partials to render for each document(see #render_document_partials) 
            partials: [:show_header, :show]
          ),
          # Configurations for specific types of index views
          :view => NestedOpenStructWithHashAccess.new(ViewConfig, 'list'),
          # Maxiumum number of spelling suggestions to offer
          :spell_max => 5,
          # Maximum number of results to show per page
          :max_per_page => 100,
          # Options for the user for number of results to show per page
          :per_page => [10,20,50,100],
          :default_per_page => nil,
          # how many searches to save in session history
          # (TODO: move the value into the configuration?)
          :search_history_window => Blacklight::Catalog::SearchHistoryWindow,
          ## deprecated; use add_facet_field :include_in_request instead;
          # if this is configured true, all facets will be included in the solr request
          # unless explicitly disabled.
          :add_facet_fields_to_solr_request => false, 
          ## deprecated; use add_index_field :include_in_request instead;
          # if this is configured true, all show and index will be included in the solr request
          # unless explicitly disabled.
          :add_field_configuration_to_solr_request => false
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
    
    def solr_document_model
      super || SolrDocument
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
      field = nil
      field ||= search_fields.values.select { |field| field.default == true }.first
      field ||= search_fields.values.first

      field
    end

    ##
    # Returns default sort field, used for simpler display in history, etc.
    # if not set, defaults to first defined sort field
    def default_sort_field
      field = nil
      field ||= sort_fields.values.select { |field| field.default == true }.first
      field ||= sort_fields.values.first

      field
    end
    
    def default_title_field
      solr_document_model.unique_key || 'id'
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
      alias_method :deep_copy, :deep_dup
      alias_method :inheritable_copy, :deep_dup
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
  end
end
