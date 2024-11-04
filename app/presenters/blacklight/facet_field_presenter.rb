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
      if in_advanced_search?
        search_state.filter(facet_field).values(except: [:filters, :missing]).any?
      else
        search_state.filter(facet_field).any?
      end
    end

    def in_advanced_search?
      search_state.params[:action] == "advanced_search"
    end

    def in_modal?
      modal_like_actions = %w[facet facet_suggest]
      modal_like_actions.include? search_state.params[:action]
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

    # Appease rubocop rules by implementing #each_value
    def each_value(&)
      values.each(&)
    end

    def paginator
      return unless display_facet

      @paginator ||= blacklight_config.facet_paginator_class.new(
        display_facet.items,
        sort: display_facet.sort,
        offset: display_facet.offset,
        prefix: display_facet.prefix,
        limit: facet_limit
      )
    end

    DEFAULT_FACET_LIMIT = 10

    # Look up facet limit for given facet_field. Will look at config, and
    # if config is 'true' will look up from Solr @response if available. If
    # no limit is available, returns nil. Used from #add_facetting_to_solr
    # to supply f.fieldname.facet.limit values in solr request (no @response
    # available), and used in display (with @response available) to create
    # a facet paginator with the right limit.
    def facet_limit
      return unless facet_field.limit

      if @display_facet
        limit = @display_facet.limit

        if limit.nil? # we didn't get or a set a limit, so infer one.
          facet_field.limit if facet_field.limit != true
        elsif limit == -1 # limit -1 is solr-speak for unlimited
          nil
        else
          limit.to_i - 1 # we added 1 to find out if we needed to paginate
        end
      else
        facet_field.limit == true ? DEFAULT_FACET_LIMIT : facet.limit
      end
    end

    delegate :blacklight_config, to: :search_state
  end
end
