# frozen_string_literal: true

module Blacklight
  class ViewCache
    def initialize
      @view_cache = {}
    end

    ##
    # @param key fetches or writes data to a cache, using the given key.
    # @yield the block to evaluate (and cache) if there is a cache miss
    def cached_view key
      @view_cache ||= {}
      if @view_cache.key?(key)
        @view_cache[key]
      else
        @view_cache[key] = yield
      end
    end
  end
end
