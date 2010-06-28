##
# Module to deal with accessing (and setting some defaults) in an array of
# hashes that describe Blacklight search fields.  Requires the base class this
# module is added to implements a #config method that returns a hash, where
# config[:search_fields] will be an array of hashes describing search fields.
#
# = Search Field Configuration Hash =
# [:display_label]
#   "Title",  # user-displayable label
# [:qt]
#   "search", # Solr qt param, request handler, defaults to Blacklight.config[:default_qt] if left blank.
# [:solr_parameters]
#   {:qf => "something"} # optional hash of additional parameters to pass to solr for searches on this field.
# [:solr_local_parameters]
#   {:qf => "$something"} # optional hash of additional parameters that will be passed using Solr LocalParams syntax, that can use dollar sign to reference other solr variables.
# [:include_in_simple_select]
#   false.  Defaults to true, but you can set to false to have a search field defined for deep-links or BL extensions, but not actually included in the HTML select for simple search choice.
# 
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
    config[:search_fields].collect {|obj| normalize_config(obj)}
  end
  memoize :search_field_list

  # Returns suitable argument to options_for_select method, to create
  # an html select based on #search_field_list. Skips search_fields
  # marked :include_in_simple_select => false
  def search_field_options_for_select
    search_field_list.collect do |field_def|
      [field_def[:display_label],  field_def[:key]] unless field_def[:include_in_simple_select] == false
    end.compact
  end

  # Looks up a search field config hash from search_field_list having
  # a certain supplied :key. 
  def search_field_def_for_key(key)
    return nil if key.blank?
    search_field_list.find {|c| c[:key] == key}
  end

  # Returns default search field, used for simpler display in history, etc.
  # if not set in config, defaults to first field listed in #search_field_list
  def default_search_field
    config[:default_search_field] || search_field_list[0]
  end
  memoize :default_search_field

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


    # Accept legacy two-element array, if it's not a Hash, assume it's legacy.
    # No great way to 'duck type' here. 
    unless ( field_hash.kind_of?(Hash))      
      # Consistent with legacy behavior where two fields can have the same label,
      # as long as they have different qt's, we base the unique :key on :qt. 
      field_hash = {:display_label => field_hash[0], :key => field_hash[1], :qt => field_hash[1]}
    else
      # Make a copy of passed in Hash so we don't alter original. 
      field_hash = field_hash.clone
    end
    
    # If no key was provided, turn the display label into one.      
    field_hash[:key] ||= field_hash[:display_label].downcase.gsub(/[^a-z0-9]+/,'_')

    # If no :qt was provided, take from config default
    field_hash[:qt] ||= config[:default_qt]
  
    field_hash
  end
  
  
end
