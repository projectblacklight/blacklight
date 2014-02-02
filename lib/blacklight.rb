# -*- encoding : utf-8 -*-
require 'kaminari'
require 'rsolr'
module Blacklight

  autoload :Configurable, 'blacklight/configurable'
  autoload :Configuration, 'blacklight/configuration'
  autoload :SearchFields, 'blacklight/search_fields'

  autoload :Solr, 'blacklight/solr'
  
  autoload :SolrHelper, 'blacklight/solr_helper'
  
  autoload :Exceptions, 'blacklight/exceptions'

  autoload :User, 'blacklight/user'

  autoload :Controller, 'blacklight/controller'
  autoload :Base, 'blacklight/base'
  autoload :Catalog,    'blacklight/catalog'

  autoload :Routes, 'blacklight/routes'

  autoload :OpenStructWithHashAccess, 'blacklight/utils'
  autoload :SolrResponse, 'blacklight/solr_response'
  autoload :Facet, 'blacklight/facet'

  extend SearchFields
  
  require 'blacklight/version'
  require 'blacklight/engine' if defined?(Rails)
  
  class << self
    attr_accessor :solr, :solr_config
  end

  def self.solr_file
    "#{::Rails.root.to_s}/config/solr.yml"
  end
  
  def self.add_routes(router, options = {})
    Blacklight::Routes.new(router, options).draw
  end

  def self.solr
    @solr ||=  RSolr.connect(Blacklight.solr_config)
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
      raise "You are missing a solr configuration file: #{solr_file}. Have you run \"rails generate blacklight:install\"?"  
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
  
end
