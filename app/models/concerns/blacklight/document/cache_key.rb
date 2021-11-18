# frozen_string_literal: true

# This module provides the cache key which can be used by rails
# caching to determine when to expire a particular object's cache
# See http://apidock.com/rails/ActiveRecord/Integration/cache_key
# This key should be used in conjunction with additional data to
# determine when a document can be cached (e.g. for different view
# types in search results like gallery and list)
module Blacklight::Document::CacheKey
  def cache_key
    if new_record?
      "#{self.class.model_name.cache_key}/new"
    elsif key? cache_version_key
      cache_version_value = self[cache_version_key]
      "#{self.class.model_name.cache_key}/#{id}-#{Array(cache_version_value).join}"
    else
      "#{self.class.model_name.cache_key}/#{id}"
    end
  end

  def cache_version_key
    :_version_
  end
end
