# frozen_string_literal: true

module Blacklight
  # Presenter for the search context (e.g. previous + next links) of a single document within a search result.
  class SearchContextPresenter
    attr_reader :response, :counter, :view_context

    def initialize(response, view_context:, counter: nil)
      @response = response
      @counter = counter
      @view_context = view_context
    end

    # Provide backwards-compatibility for downstream code expecting the old hash-based response.
    delegate_missing_to :to_hash

    def to_hash
      @to_hash ||= {
        prev: previous_document,
        next: next_document
      }
    end

    def total
      response.total.to_i
    end

    def previous_document
      return if counter && counter <= 1

      response.documents.first
    end

    def next_document
      return if counter && counter >= response.total

      response.documents.last
    end
  end
end
