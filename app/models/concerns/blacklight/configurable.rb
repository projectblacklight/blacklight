# frozen_string_literal: true
module Blacklight::Configurable
  extend ActiveSupport::Concern

  included do
    helper_method :blacklight_config if respond_to? :helper_method
  end
  
  #instance methods for blacklight_config, so get a deep copy of the class-level config
  def blacklight_config
    @blacklight_config ||= self.class.blacklight_config.deep_copy
  end
  attr_writer :blacklight_config

  module ClassMethods   
    def copy_blacklight_config_from(other_class)
      self.blacklight_config = other_class.blacklight_config.inheritable_copy
    end
    
    # lazy load a deep_copy of superclass if present, else
    # a default_configuration, which will be legacy load or new empty config. 
    # note the @blacklight_config variable is a ruby 'instance method on class
    # object' that won't be automatically available to subclasses, that's why
    # we lazy load to 'inherit' how we want. 
    def blacklight_config
      @blacklight_config ||= if superclass.respond_to?(:blacklight_config)
        superclass.blacklight_config.deep_copy
      else
        default_configuration
      end
    end
    attr_writer :blacklight_config
    
    #simply a convenience method for blacklight_config.configure
    def configure_blacklight(*args, &block)
      blacklight_config.configure(*args, &block)
    end

    ##
    # The default configuration object
    def default_configuration
      Blacklight::Configurable.default_configuration.inheritable_copy
    end
  end

  def self.default_configuration
      @default_configuration ||= Blacklight::Configuration.new
  end

  def self.default_configuration= config
    @default_configuration = config
  end
end
