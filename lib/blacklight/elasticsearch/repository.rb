module Blacklight::Elasticsearch
  class Repository < Blacklight::AbstractRepository
    class SingleDocumentResponse
      def initialize doc
        @doc = doc
      end

      def documents
        [@doc]
      end
    end

    class FacetResponse
      attr_reader :name, :aggregation

      def initialize name, aggregation
        @name = name
        @aggregation = aggregation
      end

      def items
        aggregation.buckets.map do |b|
          OpenStruct.new(name: name, value: b['key'], hits: b['doc_count'])
        end
      end

      def sort; end
      def offset; end
      def limit; end
    end
    
    class SearchResponse
      attr_reader :response, :params
      
      include Kaminari::PageScopeMethods
      include Kaminari::ConfigurationMethods::ClassMethods

      def initialize response, params
        @response = response
        @params = params
      end

      def grouped?
        false
      end

      delegate :results, :total, to: :response

      alias_method :documents, :results

      delegate :empty?, to: :results

      def facet_by_field_name field_name
        if agg = response.response.aggregations[field_name]
          FacetResponse.new(field_name, agg)
        end
      end

      def facet_pivot *args
        {}
      end

      def facet_queries *args
        []
      end

      alias_method :total_count, :total
      
      def start
        params['from'] || 0
      end
      alias_method :offset_value, :start
      
      def limit_value
        params['size'] || response.size
      end
      alias_method :rows, :limit_value

      def sort
        nil
      end

      def spelling
        nil
      end

    end

    ##
    # Find a single document result (by id) using the document configuration
    # @param [String] document's unique key value
    def find id, params = {}
      response = SingleDocumentResponse.new(blacklight_config.document_model.find(id))
      response
    end

    ##
    # Execute a search query
    # @param [Hash] elastic search query parameters
    def search params = {}
      Rails.logger.info "ES parameters: #{params.inspect}"
      SearchResponse.new(blacklight_config.document_model.search(params), params)
    end

  end
end