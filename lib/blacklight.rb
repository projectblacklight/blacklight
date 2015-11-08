require 'kaminari'
require 'deprecation'
require 'blacklight/utils'

module Blacklight
  autoload :AbstractRepository, 'blacklight/abstract_repository'
  autoload :Configuration, 'blacklight/configuration'
  autoload :Exceptions,  'blacklight/exceptions'
  autoload :Parameters,  'blacklight/parameters'
  autoload :Routes,      'blacklight/routes'
  autoload :SearchBuilder, 'blacklight/search_builder'
  autoload :SearchState, 'blacklight/search_state'
  autoload :Solr, 'blacklight/solr'

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

  def self.blacklight_config_file
    "#{::Rails.root}/config/blacklight.yml"
  end

  ##
  # The default index connection for the search index
  def self.default_index
    @default_index ||= repository_class.new(default_configuration)
  end

  ##
  # The configured repository class. By convention, this is
  # the class Blacklight::{name of the adapter}::Repository, e.g.
  #   elastic_search => Blacklight::ElasticSearch::Repository
  def self.repository_class
    case connection_config[:adapter]
    when 'solr'
      Blacklight::Solr::Repository
    when /::/
      connection_config[:adapter].constantize
    else
      Blacklight.const_get("#{connection_config[:adapter]}/Repository".classify)
    end
  end

  ##
  # The default Blacklight configuration.
  def self.default_configuration
    Blacklight::Configuration.new
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
      raise "You are missing a configuration file: #{blacklight_config_file}. Have you run \"rails generate blacklight:install\"?"
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
