module Blacklight
  module Ar
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
        attr_reader :name, :counts

        def initialize name, counts
          @name = name
          @counts = counts
        end

        def items
          counts.map do |key, count|
            OpenStruct.new(name: name, value: key, hits: count)
          end
        end

        def sort; end
        def offset; end
        def limit; end
      end

      class Aggregations
        def initialize response
          @response = response
        end

        def [] key
          FacetResponse.new(key, @response.response.group(key).count)
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

        def grouped?
          false
        end

        def results
          response
        end

        def total
          response.total_count
        end

        alias_method :documents, :results

        delegate :empty?, to: :results

        def aggregations
          Aggregations.new(self)
        end

        alias_method :total_count, :total
        
        def start
          params.start
        end
        alias_method :offset_value, :start
        
        def limit_value
          params.per
        end
        alias_method :rows, :limit_value

        def sort
          params.send(:sort)
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
        Rails.logger.info "AR parameters: #{params.inspect}"
        SearchResponse.new(params.search(blacklight_config.document_model), params)
      end
    end

    class SearchBuilder < Blacklight::SearchBuilder
      self.default_processor_chain = []

      attr_accessor :scopes

      def initialize *args
        super
        self.scopes = []
      end

      def query *args
        self
      end

      def search model
        scope = model.page(page).per(per).padding(start % per)

        if sort
          scope = scope.order(sort)
        end
        
        (blacklight_params[:f] || {}).each do |field, values|
          scope = scope.where(field => Array(values))
        end

        scope.all
      end


    end
  end
end