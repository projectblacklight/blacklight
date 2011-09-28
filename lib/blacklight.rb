# -*- encoding : utf-8 -*-
require 'kaminari'
require 'blacklight/kaminari_relevant_pages_patch'
require 'marc'
require 'rsolr'
require 'rsolr-ext'

module Blacklight

  autoload :Configurable, 'blacklight/configurable'
  autoload :SearchFields, 'blacklight/search_fields'

  autoload :Solr, 'blacklight/solr'
  autoload :Marc, 'blacklight/marc'
  
  autoload :SolrHelper, 'blacklight/solr_helper'
  
  autoload :Exceptions, 'blacklight/exceptions'

  autoload :User, 'blacklight/user'

  autoload :CommaLinkRenderer, 'blacklight/comma_link_renderer'

  autoload :Controller, 'blacklight/controller'
  autoload :Catalog,    'blacklight/catalog'

  autoload :Routes, 'blacklight/routes'

  extend Configurable
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
        raise "You are missing a solr configuration file: #{solr_file}. Have you run \"rails generate blacklight\"?" unless File.exists?(solr_file) 
        solr_config = YAML::load(File.open(solr_file))
        raise "The #{::Rails.env} environment settings were not found in the solr.yml config" unless solr_config[::Rails.env]
        solr_config[::Rails.env].symbolize_keys
      end
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
