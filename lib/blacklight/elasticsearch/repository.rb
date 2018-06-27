# frozen_string_literal: true

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

    class NullSpelling
      def words
        []
      end
    end

    class SearchResponse
      attr_reader :response, :params

      include Kaminari::PageScopeMethods
      include Kaminari::ConfigurationMethods::ClassMethods

      def initialize response, params
        @response = response
        @params = params
      end

      def inspect
        "#<#{self.class.name} results=#{response.results}>"
      end

      def grouped?
        false
      end

      delegate :results, :total, to: :response

      alias documents results

      delegate :empty?, to: :results

      def facet_by_field_name field_name
        agg = response.response.aggregations[field_name]
        return unless agg
        FacetResponse.new(field_name, agg)
      end

      def docs
        response.results
      end

      # TODO: not yet implemented
      def aggregations
        {}
      end

      def facet_pivot *_args
        {}
      end

      def facet_queries *_args
        []
      end

      alias total_count total

      def start
        params['from'] || 0
      end
      alias offset_value start

      def limit_value
        params['size'] || response.size
      end
      alias rows limit_value

      def sort
        nil
      end

      def spelling
        NullSpelling.new
      end
    end

    ##
    # Find a single document result (by id) using the document configuration
    # @param [String] document's unique key value
    def find id, _params = {}
      response = SingleDocumentResponse.new(connection.find(id))
      response
    rescue Elasticsearch::Persistence::Repository::DocumentNotFound
      raise Blacklight::Exceptions::RecordNotFound
    end

    ##
    # Execute a search query
    # @param [Hash] elastic search query parameters
    def search params = {}
      Rails.logger.info "ES parameters: #{params.inspect}"
      SearchResponse.new(connection.search(params.to_h), params)
    end

    private

    def build_connection
      c = Elasticsearch::Client.new connection_config.except(:adapter, :index)
      idx = connection_config[:index]
      Elasticsearch::Persistence::Repository.new do
        # Configure the Elasticsearch client
        client c

        # Set a custom index name
        index idx

        type :document

        klass ElasticsearchDocument

        settings number_of_shards: 1 do
          mapping do
            indexes :text, analyzer: 'snowball'
          end
        end
      end
    end
  end
end
