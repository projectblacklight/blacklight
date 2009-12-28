##
# Module to deal with accessing (and setting some defaults) in an array of
# hashes that describe Blacklight search fields.  Requires the base class this
# module is added to implements a #config method that returns a hash, where
# config[:search_fields] will be an array of hashes describing search fields.
#
# = Search Field Configuration Hash =
# { :display_label => "Title",  # user-displayable label
#   :qt => "search" # Solr qt param, request handler, defaults to Blacklight.config[:default_qt] if left blank. 
# }
# Optionally you can supply a :key, which is what Blacklight will use
# to identify this search field in HTTP query params. If no :key is
# supplied, one will be computed from the :display_label. If that will
# result in a collision of keys, you should supply one explicitly. 
#
##
module Blacklight::SearchFields
  extend ActiveSupport::Memoizable

  # Looks up search field config list from config[:search_fields], and
  # 'normalizes' all field config hashes using normalize_config method. 
  # Memoized for efficiency of normalization. 
  def search_field_list
    config[:search_fields].collect {|hash| normalize_config(hash)}
  end
  memoize :search_field_list

  # Returns suitable argument to options_for_select method, to create
  # an html select based on #search_field_list
  def search_field_options_for_select
    search_field_list.collect do |field_def|
      [field_def[:display_label],  field_def[:key]]
    end
  end

  # Looks up a search field config hash from search_field_list having
  # a certain supplied :key. 
  def search_field_def_for_key(key)
    return nil if key.blank?
    search_field_list.find {|c| c[:key] == key}
  end

  # Shortcut for commonly needed operation, look up display
  # label for the key specified. Returns "Keyword" if a label
  # can't be found. 
  def label_for_search_field(key)
    field_def = search_field_def_for_key(key)
    if field_def && field_def[:display_label]
       field_def[:display_label]
    else
       "Keyword"
    end            
  end

  protected
  # Fill in missing default values in a search_field config hash.
  def normalize_config(field_hash)
    # Make a copy so we don't alter original. 
    field_hash = field_hash.clone      
    # If no key was provided, turn the display label into one.      
    field_hash[:key] ||= field_hash[:display_label].downcase.gsub(/[^a-z0-9]+/,'_')

    # If no :qt was provided, take from config default
    field_hash[:qt] ||= Blacklight.config[:default_qt]
  
    field_hash
  end
  
  
end
