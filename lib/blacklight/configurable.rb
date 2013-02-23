# -*- encoding : utf-8 -*-
module Blacklight::Configurable
  extend ActiveSupport::Concern

  included do
    helper_method :blacklight_config if respond_to? :helper_method
  end
  
  attr_writer :blacklight_config
  
  #instance methods for blacklight_config, so get a deep copy of the class-level config
  def blacklight_config
    @blacklight_config ||= begin
      c = self.class.default_configuration
      self.class.blacklight_config_procs.each do |block|
        c.configure &block
      end 
      c
    end
  end

  module ClassMethods   
    attr_writer :blacklight_config

    def blacklight_config_procs
      @blacklight_config_procs ||= begin
        p = []

        if superclass.respond_to?(:blacklight_config_procs)
          p += superclass.blacklight_config_procs
        end

        p
      end
    end

    def blacklight_config_procs= procs
      @blacklight_config_procs ||= procs
      @blacklight_config = nil
    end

    def copy_blacklight_config_from(other_class)
      self.blacklight_config_procs += other_class.blacklight_config_procs
    end
    
    # lazy load a deep_copy of superclass if present, else
    # a default_configuration, which will be legacy load or new empty config. 
    # note the @blacklight_config variable is a ruby 'instance method on class
    # object' that won't be automatically available to subclasses, that's why
    # we lazy load to 'inherit' how we want. 
    def blacklight_config
      @blacklight_config ||= begin
        c = default_configuration
        self.blacklight_config_procs.each do |block|
          c.configure &block
        end 
        c
      end
    end

    #simply a convenience method for blacklight_config.configure
    def configure_blacklight(*args, &block)
      self.blacklight_config_procs << block
      @blacklight_config = nil
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
