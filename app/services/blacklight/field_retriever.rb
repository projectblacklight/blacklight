module Blacklight
  class FieldRetriever
    # @param [SolrDocument] document
    # @param [Blacklight::Configuration::Field] field_config solr field configuration
    def initialize(document, field_config)
      @document = document
      @field_config = field_config
    end

    attr_reader :document, :field_config
    delegate :field, to: :field_config
    
    # @return [Array]
    def fetch
      Array.wrap(
        case    
          when field_config.highlight
            retrieve_highlight
          when field_config.accessor
            retieve_using_accessor
          when field_config
            retrieve_simple
        end
      )
    end

    private

      def retrieve_simple
        # regular document field
        if field_config.default and field_config.default.is_a? Proc
          document.fetch(field_config.field, &field_config.default)
        else
          document.fetch(field_config.field, field_config.default)
        end
      end

      def retieve_using_accessor
        # implicit method call
        if field_config.accessor == true
          document.send(field)
        # arity-1 method call (include the field name in the call)
        elsif !field_config.accessor.is_a?(Array) && document.method(field_config.accessor).arity != 0
          document.send(field_config.accessor, field)
        # chained method calls
        else
          Array(field_config.accessor).inject(document) do |result, method|
            result.send(method)
          end
        end
      end

      def retrieve_highlight
        # retrieve the document value from the highlighting response
        document.highlight_field(field_config.field).map(&:html_safe) if document.has_highlight_field? field_config.field
      end
  end
end
