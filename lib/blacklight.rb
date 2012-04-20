# -*- encoding : utf-8 -*-
require 'blacklight/kaminari_relevant_pages_patch' 
require 'rsolr'
require 'rsolr-ext'

module Blacklight

  autoload :Configurable, 'blacklight/configurable'
  autoload :Configuration, 'blacklight/configuration'
  autoload :GlobalConfigurable, 'blacklight/global_configurable'
  autoload :SearchFields, 'blacklight/search_fields'

  autoload :Solr, 'blacklight/solr'
  autoload :Marc, 'blacklight/marc'
  
  autoload :SolrHelper, 'blacklight/solr_helper'
  
  autoload :Exceptions, 'blacklight/exceptions'

  autoload :User, 'blacklight/user'

  autoload :Controller, 'blacklight/controller'
  autoload :Catalog,    'blacklight/catalog'

  autoload :Routes, 'blacklight/routes'

  autoload :OpenStructWithHashAccess, 'blacklight/utils'

  extend GlobalConfigurable
  extend SearchFields
  
  require 'blacklight/version'
  require 'blacklight/engine' if defined?(Rails)
  
  class << self
    attr_accessor :solr, :solr_config
  end
  
  # Adding a little jruby support
  def self.jruby?
    defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby" 
  end

  def self.solr_file
    "#{::Rails.root.to_s}/config/solr.yml"
  end
  
  def self.add_routes(router, options = {})
    Blacklight::Routes.new(router, options).draw
  end

  def self.solr
    @solr ||=  RSolr::Ext.connect(Blacklight.solr_config)
  end

  def self.solr_config
    @solr_config ||= begin
        raise "The #{::Rails.env} environment settings were not found in the solr.yml config" unless solr_yml[::Rails.env]
        solr_yml[::Rails.env].symbolize_keys
      end
  end

  def self.solr_yml
    require 'erb'
    require 'yaml'

    return @solr_yml if @solr_yml
    unless File.exists?(solr_file)
      raise "You are missing a solr configuration file: #{solr_file}. Have you run \"rails generate blacklight\"?"  
    end

    begin
      @solr_erb = ERB.new(IO.read(solr_file)).result(binding)
    rescue Exception => e
      raise("solr.yml was found, but could not be parsed with ERB. \n#{$!.inspect}")
    end

    begin
      @solr_yml = YAML::load(@solr_erb)
    rescue StandardError => e
      raise("solr.yml was found, but could not be parsed.\n")
    end

    if @solr_yml.nil? || !@solr_yml.is_a?(Hash)
      raise("solr.yml was found, but was blank or malformed.\n")
    end

    return @solr_yml
  end

  def self.logger
    ::Rails.logger
  end

  #############  
  # Methods for figuring out path to BL plugin, and then locate various files
  # either in the app itself or defaults in the plugin -- whether you are running
  # from the plugin itself or from an actual app using te plugin.
  # In a seperate module so it can be used by both Blacklight class, and
  # by rake tasks without loading the whole Rails environment. 
  #############
  
  # returns the full path the the blacklight plugin installation
  def self.root
    @root ||= File.expand_path(File.dirname(File.dirname(__FILE__)))
  end

  # This is useful for modifying Blacklight models.
  # In the main app you can then do this:
  # require "#{MyEngine.models_dir}/bookmark"
  # class Bookmark
  # ...
  # end
  # BE AWARE - When you do this, you are monkey patching Blacklight
  # we should eventually find a better way - such as the acts_as pattern
  def self.models_dir
    "#{root}/app/models"
  end
  
  def self.controllers_dir
    "#{root}/app/controllers"
  end

  
  # Searches Rails.root then Blacklight.root for a valid path
  # returns a full path if a valid path is found
  # returns nil if nothing is found.
  # First looks in Rails.root, then Blacklight.root
  #
  # Example:
  # full_path_to_solr_marc_jar = Blacklight.locate_path 'solr_marc', 'SolrMarc.jar'
  
  def self.locate_path(*subpath_fragments)
    subpath = subpath_fragments.join('/')
    base_match = [Rails.root, self.root].find do |base|
      File.exists? File.join(base, subpath)
    end
    File.join(base_match.to_s, subpath) if base_match
  end
  
end
