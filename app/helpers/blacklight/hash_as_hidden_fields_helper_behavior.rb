# frozen_string_literal: true
# Rails Helper methods to take a hash and turn it to form <input type="hidden">
# fields, works with hash nested with other hashes and arrays, standard rails
# serialization style.  Oddly while Hash#to_query will do this for a URL
# query parameters, there seems to be no built in way to do it to create
# hidden form fields instead.
#
# Code taken from http://marklunds.com/articles/one/314
#
# This is used to serialize a complete current query from current params
# to form fields used for sort and change per-page
module Blacklight::HashAsHiddenFieldsHelperBehavior
  extend Deprecation

  ##
  # Writes out zero or more <input type="hidden"> elements, completely
  # representing a hash passed in using Rails-style request parameters
  # for hashes nested with arrays and other hashes.
  #
  # @deprecated
  # @param [Hash] hash
  # @return [String]
  def render_hash_as_hidden_fields(hash)
    render Blacklight::HiddenSearchStateComponent.new(params: hash)
  end
  deprecation_deprecate render_hash_as_hidden_fields: 'Use Blacklight::HiddenSearchStateComponent instead'
end
