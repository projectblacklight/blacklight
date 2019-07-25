# frozen_string_literal: true

##
# Module to deal with accessing (and setting some defaults) in an array of
# hashes that describe Blacklight search fields.  Requires the base class this
# module is added to implements a #blacklight_config method that returns a hash, where
# blacklight_config[:search_fields] will be an array of hashes describing search fields.
#
# = Search Field blacklight_configuration Hash =
# [:key]
#   "title", required, unique key used in search URLs to specify search_field
# [:label]
#   "Title",  # user-displayable label, optional, if not supplied :key.titlecase will be used
# [:qt]
#   "search", # Solr qt param, request handler, usually can be left blank; defaults to nil if not explicitly specified
# [:solr_parameters]
#   { :qf => "something" } # optional hash of additional parameters to pass to solr for searches on this field.
# [:solr_local_parameters]
#   { :qf => "$something" } # optional hash of additional parameters that will be passed using Solr LocalParams syntax, that can use dollar sign to reference other solr variables.
# [:include_in_simple_select]
#   false.  Defaults to true, but you can set to false to have a search field defined for deep-links or BL extensions, but not actually included in the HTML select for simple search choice.
#
# Optionally you can supply a :key, which is what Blacklight will use
# to identify this search field in HTTP query params. If no :key is
# supplied, one will be computed from the :label. If that will
# result in a collision of keys, you should supply one explicitly.
#
##
module Blacklight::SearchFields
  # Looks up search field config list from blacklight_config[:search_fields], and
  # 'normalizes' all field config hashes using normalize_config method.
  def search_field_list
    blacklight_config.search_fields.values
  end

  # Returns default search field, used for simpler display in history, etc.
  # if not set in blacklight_config, defaults to first field listed in #search_field_list
  def default_search_field
    blacklight_config.default_search_field || search_field_list.first
  end
end
