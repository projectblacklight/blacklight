# frozen_string_literal: true

module Blacklight
  class FacetFieldPresenter
    attr_reader :facet_field, :display_facet, :view_context, :search_state

    delegate :key, to: :facet_field
    delegate :field_name, to: :display_facet

    def initialize(facet_field, display_facet, view_context, search_state = view_context.search_state)
      @facet_field = facet_field
      @display_facet = display_facet
      @view_context = view_context
      @search_state = search_state
    end

    def collapsed?
      !active? && facet_field.collapse
    end

    def active?
      Deprecation.silence(Blacklight::FacetsHelperBehavior) do
        view_context.facet_field_in_params?(key)
      end
    end

    def in_modal?
      search_state.params[:action] == "facet"
    end

    def modal_path
      return unless paginator

      view_context.search_facet_path(id: key) unless paginator&.last_page?
    end

    def label
      view_context.facet_field_label(key)
    end

    def values
      search_state&.filter(facet_field)&.values || []
    end

    def paginator
      return unless display_facet

      Deprecation.silence(Blacklight::Facet) do
        @paginator ||= view_context.facet_paginator(facet_field, display_facet)
      end
    end
  end
end
