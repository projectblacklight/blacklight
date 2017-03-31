module Blacklight
  class DocumentFactory
    def self.build(data, response, options)
      document_model(data, options).new(data, response)
    end

    def self.document_model(_data, options)
      options[:solr_document_model] || options[:document_model] || SolrDocument
    end
  end
end
