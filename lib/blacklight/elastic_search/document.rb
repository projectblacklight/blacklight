# frozen_string_literal: true

module Blacklight::ElasticSearch
  # Mixin for a class representing a single document returned from
  # Elasticsearch. This is the Elasticsearch analog to
  # Blacklight::Solr::Document.
  module Document
    extend ActiveSupport::Concern
    include Blacklight::Document
    include Blacklight::Document::ActiveModelShim

    # More-like-this is not supported by the Elasticsearch adapter.
    def more_like_this
      []
    end

    def has_highlight_field?(field)
      highlighting = self['_highlighting']
      return false if highlighting.blank?

      highlighting.key?(field.to_s)
    end

    def highlight_field(field)
      return unless has_highlight_field?(field)

      Array(self['_highlighting'][field.to_s]).map(&:html_safe)
    end
  end
end
