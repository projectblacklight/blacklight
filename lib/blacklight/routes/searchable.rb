module Blacklight
  module Routes
    class Searchable
      def initialize(defaults = {})
        @defaults = defaults
      end

      def call(mapper, options = {})
        options = @defaults.merge(options)

        mapper.match '/', action: 'index', as: 'search', via: [:get, :post]

        mapper.post ":id/track", action: 'track', as: 'track'

        mapper.get "opensearch"
        mapper.get "facet/:id", action: 'facet', as: 'facet'
      end
    end
  end
end
