# frozen_string_literal: true

module Blacklight::Solr
  class FieldReflectionSearchBuilder < SearchBuilder
    self.default_processor_chain = [:add_params]

    def add_params(request)
      request.reverse_merge!({ fl: '*', 'json.nl' => 'map' })
    end
  end
end
