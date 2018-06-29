# frozen_string_literal: true

module Blacklight::Elasticsearch
  module Response
    module Facets
      # represents a facet; which is a field and its values
      class FacetField
        attr_reader :name, :items

        def initialize name, items
          @name = name
          @items = items
        end

        def sort; end

        def offset; end

        def limit; end

        def prefix; end
      end

      # represents a facet value; which is a field value and its hit count
      class FacetItem < OpenStruct
        def label
          super || value
        end

        def as_json(props = nil)
          table.as_json(props)
        end
      end
    end
  end
end
