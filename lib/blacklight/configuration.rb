module Blacklight
  ##
  # Blacklight::Configuration holds the configuration for a Blacklight::Controller, including
  # fields to display, facets to show, sort options, and search fields.
  class Configuration < OpenStructWithHashAccess

    # Set up Blacklight::Configuration.default_values to contain 
    # the basic, required Blacklight fields
    class << self; attr_accessor :default_values; end
    @default_values = {
      :default_solr_params => {},
      :default_search_field => nil,
      :show => OpenStructWithHashAccess.new,
      :index => OpenStructWithHashAccess.new,
      :spell_max => 5
    }


    # XXX this isn't very pretty, but it works.
    require 'blacklight/configuration/fields'
    require 'blacklight/configuration/solr_field'
    require 'blacklight/configuration/search_field'
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

    ##
    # Helper method for loading a legacy blacklight configuration into the new style Blacklight::Configuration
    def self.from_legacy_configuration config
      config = Marshal.load(Marshal.dump(config))
  
      Blacklight::Configuration.new  do |blacklight_config|
        # SolrHelper#default_solr_parameters needs to iterate over the keys, so this can't be a Struct
        blacklight_config.default_solr_params = config[:default_solr_params]
    
        config[:facet][:field_names].each do |x|
          blacklight_config.add_facet_field x, :limit => config[:facet][:limits][x], :label => config[:facet][:labels][x]
        end if config[:facet] and config[:facet][:field_names]
    
        config[:index_fields][:field_names].each do |x|
          blacklight_config.add_index_field x, :label => config[:index_fields][:labels][x]
        end if config[:index_fields]
    
        config[:show_fields][:field_names].each do |x|
          blacklight_config.add_show_field x, :label => config[:show_fields][:labels][x]
        end if config[:show_fields]
    
        config[:search_fields].each do |x|
          unless x.is_a? Hash
            x = { :label => x[0], :key => x[1], :qt => x[1]}
          end

          x[:label] ||= x.delete(:display_label)
    
          blacklight_config.add_search_field x[:key], x
        end if config[:search_fields]
    
        config[:sort_fields].each do |field|
          label, sort = field
          blacklight_config.add_sort_field sort, :label => label
        end if config[:sort_fields]
    
        config.reject { |key, value| [:default_solr_params, :facet, :index_fields, :show_fields, :search_fields, :sort_fields].include? key }.each do |key,value|
          blacklight_config.send("#{key}=", (Blacklight::OpenStructWithHashAccess.new(value) if value.is_a? Hash) || value)
        end
      end                  
    end
  end
end
