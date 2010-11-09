module Blacklight

  
  autoload :CoreExt, 'blacklight/core_ext.rb'
  # load up the CoreExt by referencing it:
  CoreExt
  
  autoload :Configurable, 'blacklight/configurable'
  autoload :SearchFields, 'blacklight/search_fields'

  autoload :Solr, 'blacklight/solr.rb'
  autoload :Marc, 'blacklight/marc.rb'
  
  autoload :SolrHelper, 'blacklight/solr_helper'
  
  autoload :Routes, 'blacklight/routes'
  
  extend Configurable
  extend SearchFields
  
  class << self
    attr_accessor :solr, :solr_config
  end
  
  # The configuration hash that gets used by RSolr.connect
  @solr_config ||= {}
  
  # Just returning a string for the Blacklight version number.
  # I've just put master here now, should it say when it's running under master?  (Master?)
  # We need to find a better way of increasing this number automatically during releases, but this is a good way for now.
  def self.version
    "2.7.0"
  end
  
  def self.init
    
    solr_config = YAML::load(File.open("#{RAILS_ROOT}/config/solr.yml"))
    raise "The #{RAILS_ENV} environment settings were not found in the solr.yml config" unless solr_config[RAILS_ENV]
    
    Blacklight.solr_config[:url] = solr_config[RAILS_ENV]['url']
    
    if Gem.available? 'curb'
      require 'curb'
      Blacklight.solr = RSolr::Ext.connect(Blacklight.solr_config.merge(:adapter=>:curb))
    else
      Blacklight.solr = RSolr::Ext.connect(Blacklight.solr_config)
    end
    
    # set the SolrDocument.connection to Blacklight.solr
    SolrDocument.connection = Blacklight.solr
    logger.info("BLACKLIGHT: running version #{Blacklight.version}")
    logger.info("BLACKLIGHT: initialized with Blacklight.solr_config: #{Blacklight.solr_config.inspect}")
    logger.info("BLACKLIGHT: initialized with Blacklight.solr: #{Blacklight.solr.inspect}")
    logger.info("BLACKLIGHT: initialized with Blacklight.config: #{Blacklight.config.inspect}")
    
  end

  def self.logger
    RAILS_DEFAULT_LOGGER
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
    @root ||= File.expand_path File.join(__FILE__, '..', '..')
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