module Blacklight
  ##
  # Blacklight::Configuration holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Configuration < OpenStructWithHashAccess

    # Set up Blacklight::Configuration.default_values to contain 
    # the basic, required Blacklight fields
    class << self; attr_accessor :default_values; end
    @default_values = {
      :solr_path => 'select',
      :solr_request_handler => 'search',
      :default_solr_params => {},
      :document_solr_request_handler => nil,
      :default_document_solr_params => {},
      :show => OpenStructWithHashAccess.new(:html_title => SolrDocument.unique_key, :heading => SolrDocument.unique_key),
      :index => OpenStructWithHashAccess.new(:show_link => SolrDocument.unique_key),
      :spell_max => 5,
      :max_per_page => 100,
      :per_page => [10,20,50,100],
      :add_facet_fields_to_solr_request => false
    }


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

    def facet_fields_to_add_to_solr
      return facet_fields.reject { |k,v| v[:query] }.map { |k,v| v.field } if self.add_facet_fields_to_solr_request

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
