module Blacklight
  ##
  # Blacklight::Configuration holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Configuration < OpenStructWithHashAccess

    # Set up Blacklight::Configuration.default_values to contain
    # the basic, required Blacklight fields
    class << self
      def default_values
        @default_values ||= begin
          unique_key = ((SolrDocument.unique_key if defined?(SolrDocument)) || 'id')

          {
          :solr_path => 'select',
          :qt => 'search',
          :default_solr_params => {},
          :document_solr_request_handler => nil,
          :default_document_solr_params => {},
          :show => OpenStructWithHashAccess.new(:html_title => unique_key, :heading => unique_key),
          :index => OpenStructWithHashAccess.new(:show_link => unique_key, :record_display_type => 'format', :group => false),
          :spell_max => 5,
          :max_per_page => 100,
          :per_page => [10,20,50,100],
          :search_history_window => Blacklight::Catalog::SearchHistoryWindow,
          :document_index_view_types => ['list'],
          :add_facet_fields_to_solr_request => false,
          :add_field_configuration_to_solr_request => false,
          :http_method => :get
          }
        end
      end
    end


    # XXX this isn't very pretty, but it works.
    require 'blacklight/configuration/fields'
    require 'blacklight/configuration/solr_field'
    require 'blacklight/configuration/search_field'
    require 'blacklight/configuration/facet_field'
    require 'blacklight/configuration/sort_field'
    include Fields

    # Create collections of solr fields
    define_field_access :facet_field
    define_field_access :index_field
    define_field_access :show_field
    define_field_access :search_field
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

    # Returns default search field, used for simpler display in history, etc.
    # if not set, defaults to first defined search field
    def default_search_field
      field = nil
      field ||= search_fields.values.select { |field| field.default == true }.first
      field ||= search_fields.values.first

      field
    end

    # Returns default sort field, used for simpler display in history, etc.
    # if not set, defaults to first defined sort field
    def default_sort_field
      field = nil
      field ||= sort_fields.values.select { |field| field.default == true }.first
      field ||= sort_fields.values.first

      field
    end

    # Add any configured facet fields to the default solr parameters hash
    def add_facet_fields_to_solr_request!
      self.add_facet_fields_to_solr_request = true
    end

    # Add any configured facet fields to the default solr parameters hash
    def add_field_configuration_to_solr_request!
      self.add_field_configuration_to_solr_request = true
    end

    def facet_fields_to_add_to_solr
      return facet_fields.reject { |k,v| v[:query] || v[:pivot] }.map { |k,v| v.field } if self.add_facet_fields_to_solr_request

      []
    end

    ##
    # Provide a 'deep copy' of Blacklight::Configuration that can be modifyed without affecting
    # the original Blacklight::Configuration instance.
    #
    def deep_copy
      Marshal.load(Marshal.dump(self))
    end
    alias_method :inheritable_copy, :deep_copy

    ##
    # DSL helper
    def configure
      yield self if block_given?
      self
    end
  end
end
