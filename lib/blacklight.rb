# -*- encoding : utf-8 -*-
require 'kaminari'
require 'kaminari/helpers/next_page_cursor'
require 'deprecation'
require 'blacklight/utils'

module Blacklight
  autoload :Configurable, 'blacklight/configurable'
  autoload :Configuration, 'blacklight/configuration'
  autoload :SearchFields, 'blacklight/search_fields'
  autoload :SearchBuilder, 'blacklight/search_builder'
  autoload :SearchBuilderBehavior, 'blacklight/search_builder_behavior'

  autoload :Document, 'blacklight/document'
  autoload :Solr, 'blacklight/solr'

  autoload :SearchHelper,       'blacklight/search_helper'
  autoload :SolrHelper,         'blacklight/solr_helper'
  autoload :AbstractRepository, 'blacklight/abstract_repository'
  autoload :SolrRepository,     'blacklight/solr_repository'
  autoload :RequestBuilders,    'blacklight/request_builders'

  autoload :Exceptions, 'blacklight/exceptions'

  autoload :User, 'blacklight/user'

  autoload :Controller,        'blacklight/controller'
  autoload :Base,              'blacklight/base'
  autoload :Catalog,           'blacklight/catalog'
  autoload :TokenBasedUser,    'blacklight/token_based_user'
  autoload :Bookmarks,         'blacklight/bookmarks'
  autoload :DocumentPresenter, 'blacklight/document_presenter'

  autoload :Routes, 'blacklight/routes'
  
  autoload :SolrResponse, 'blacklight/solr_response'
  autoload :Facet, 'blacklight/facet'
  autoload :FacetPaginator, 'blacklight/facet_paginator'

  extend SearchFields
  extend Deprecation

  require 'blacklight/version'
  require 'blacklight/engine' if defined?(Rails)
  
  class << self
    attr_accessor :solr, :solr_config
  end

  # Secret key used to share session information with
  # other services (e.g. refworks callback urls)
  mattr_accessor :secret_key
  @@secret_key = nil

  # @deprecated
  def self.solr_file
    "#{::Rails.root}/config/solr.yml"
  end

  def self.blacklight_config_file
    "#{::Rails.root}/config/blacklight.yml"
  end

  def self.add_routes(router, options = {})
    Blacklight::Routes.new(router, options).draw
  end

  def self.solr
    Deprecation.warn Blacklight, "Blacklight.solr is deprecated and will be removed in 6.0.0. Use Blacklight.default_index.connection instead", caller
    default_index.connection
  end

  def self.default_index
    @default_index ||=  Blacklight::SolrRepository.new(Blacklight::Configuration.new)
  end

  def self.solr_config
    Deprecation.warn Blacklight, "Blacklight.solr_config is deprecated and will be removed in 6.0.0. Use Blacklight.connection_config instead", caller
    connection_config
  end

  def self.connection_config
    @connection_config ||= begin
        raise "The #{::Rails.env} environment settings were not found in the blacklight.yml config" unless blacklight_yml[::Rails.env]
        blacklight_yml[::Rails.env].symbolize_keys
      end
  end

  def self.blacklight_yml
    require 'erb'
    require 'yaml'

    return @blacklight_yml if @blacklight_yml
    unless File.exists?(blacklight_config_file)
      if File.exists?(solr_file)
        Deprecation.warn Blacklight, "Configuration is now done via blacklight.yml. Suppport for solr.yml will be removed in blacklight 6.0.0"
        return solr_yml
      else
        raise "You are missing a configuration file: #{blacklight_config_file}. Have you run \"rails generate blacklight:install\"?"
      end
    end

    begin
      blacklight_erb = ERB.new(IO.read(blacklight_config_file)).result(binding)
    rescue StandardError, SyntaxError => e
      raise("#{blacklight_config_file} was found, but could not be parsed with ERB. \n#{e.inspect}")
    end

    begin
      @blacklight_yml = YAML::load(blacklight_erb)
    rescue => e
      raise("#{blacklight_config_file} was found, but could not be parsed.\n#{e.inspect}")
    end

    if @blacklight_yml.nil? || !@blacklight_yml.is_a?(Hash)
      raise("#{blacklight_config_file} was found, but was blank or malformed.\n")
    end

    return @blacklight_yml
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
    rescue StandardError, SyntaxError => e
      raise("solr.yml was found, but could not be parsed with ERB. \n#{e.inspect}")
    end

    begin
      @solr_yml = YAML::load(@solr_erb)
    rescue => e
      raise("solr.yml was found, but could not be parsed.\n#{e.inspect}")
    end

    if @solr_yml.nil? || !@solr_yml.is_a?(Hash)
      raise("solr.yml was found, but was blank or malformed.\n")
    end

    return @solr_yml
  end

  def self.logger
    @logger ||= begin
      ::Rails.logger if defined? Rails and Rails.respond_to? :logger
    end
  end

  def self.logger= logger
    @logger = logger
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
