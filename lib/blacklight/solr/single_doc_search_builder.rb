# frozen_string_literal: true

module Blacklight::Solr
  class SingleDocSearchBuilder < SearchBuilder
    self.default_processor_chain = [:add_defaults, :add_qt, :add_unique_id]

    def initialize(scope, id, other_params)
      @other_params = other_params
      @id = id
      super(scope)
    end

    def add_defaults(request)
      request.reverse_merge!(blacklight_config.default_document_solr_params).reverse_merge!(@other_params)
    end

    def add_qt(request)
      request[:qt] ||= blacklight_config.document_solr_request_handler if blacklight_config.document_solr_request_handler
    end

    def add_unique_id(request)
      request[blacklight_config.document_unique_id_param] = @id
    end
  end
end
