# frozen_string_literal: true

require 'blacklight/search_state/filter_field'
require 'blacklight/search_state/pivot_filter_field'
require 'blacklight/search_state/range_filter_field'

module Blacklight
  # This class encapsulates the search state as represented by the query
  # parameters namely: :f, :q, :page, :per_page and, :sort
  class SearchState
    attr_reader :blacklight_config # Must be called blacklight_config, because Blacklight::Facet calls blacklight_config.

    # This method is never accessed in this class, but may be used by subclasses that need
    # to access the url_helpers
    attr_reader :controller, :params

    delegate :facet_configuration_for_field, to: :blacklight_config

    # @param [ActionController::Parameters] params
    # @param [Blacklight::Config] blacklight_config
    # @param [ApplicationController] controller used for the routing helpers
    def initialize(params, blacklight_config, controller = nil)
      @blacklight_config = blacklight_config
      @controller = controller
      @params = Blacklight::Parameters.new(params, self).permit_search_params.to_h.with_indifferent_access
    end

    def to_hash
      params.deep_dup
    end
    alias to_h to_hash

    def has_constraints?
      !(query_param.blank? && filters.blank? && clause_params.blank?)
    end

    def query_param
      params[:q]
    end

    def clause_params
      params[:clause] || {}
    end

    # @return [Blacklight::SearchState]
    def reset(params = nil)
      self.class.new(params || {}, blacklight_config, controller)
    end

    # @return [Blacklight::SearchState]
    def reset_search(additional_params = {})
      reset(reset_search_params.merge(additional_params))
    end

    ##
    # Extension point for downstream applications
    # to provide more interesting routing to
    # documents
    def url_for_document(doc, options = {})
      return doc unless routable?(doc)

      route = blacklight_config.view_config(:show).route.merge(action: :show, id: doc).merge(options)
      route[:controller] = params[:controller] if route[:controller] == :current
      route
    end

    # To build a show route, we must have a blacklight_config that has
    # configured show views, and the doc must appropriate to the config
    # @return [Boolean]
    def routable?(doc)
      return false unless respond_to?(:blacklight_config) && blacklight_config.view_config(:show).route

      doc.is_a? routable_model_for(blacklight_config)
    end

    def remove_query_params
      p = reset_search_params
      p.delete(:q)
      p
    end

    def filter_fields
      blacklight_config.facet_fields.each_value.map { |value| filter(value) }
    end

    def filters
      @filters ||= filter_fields.select(&:any?)
    end

    # @return [FilterField]
    def filter(field_key_or_field)
      field = field_key_or_field if field_key_or_field.is_a? Blacklight::Configuration::Field
      field ||= blacklight_config.facet_fields[field_key_or_field]
      field ||= Blacklight::Configuration::NullField.new(key: field_key_or_field)

      (field.filter_class || FilterField).new(field, self)
    end

    # Used in catalog/facet action, facets.rb view, for a click
    # on a facet value. Add on the facet params to existing
    # search constraints. Remove any paginator-specific request
    # params, or other request params that should be removed
    # for a 'fresh' display.
    # Change the action to 'index' to send them back to
    # catalog/index with their new facet choice.
    def add_facet_params_and_redirect(field, item)
      new_params = filter(field).add(item).to_h

      # Delete any request params from facet-specific action, needed
      # to redir to index action properly.
      request_keys = blacklight_config.facet_paginator_class.request_keys
      new_params.extract!(*request_keys.values)

      new_params
    end

    # Merge the source params with the params_to_merge hash
    # @param [Hash] params_to_merge to merge into above
    # @return [ActionController::Parameters] the current search parameters after being sanitized by Blacklight::Parameters.sanitize
    # @yield [params] The merged parameters hash before being sanitized
    def params_for_search(params_to_merge = {})
      # params hash we'll return
      my_params = to_h.merge(self.class.new(params_to_merge, blacklight_config, controller))

      if block_given?
        yield my_params
      end

      if my_params[:page] && (my_params[:per_page] != params[:per_page] || my_params[:sort] != params[:sort])
        my_params[:page] = 1
      end

      Parameters.sanitize(my_params)
    end

    def page
      [params[:page].to_i, 1].max
    end

    def per_page
      params[:rows].presence&.to_i ||
        params[:per_page].presence&.to_i ||
        blacklight_config.default_per_page
    end

    def sort_field
      if sort_field_key.blank?
        # no sort param provided, use default
        blacklight_config.default_sort_field
      else
        # check for sort field key
        blacklight_config.sort_fields[sort_field_key]
      end
    end

    def search_field
      blacklight_config.search_fields[search_field_key]
    end

    def facet_page
      [params[facet_request_keys[:page]].to_i, 1].max
    end

    def facet_sort
      params[facet_request_keys[:sort]]
    end

    def facet_prefix
      params[facet_request_keys[:prefix]]
    end

    private

    def routable_model_for(blacklight_config)
      blacklight_config.document_model || ::SolrDocument
    end

    def search_field_key
      params[:search_field]
    end

    def sort_field_key
      params[:sort]
    end

    def facet_request_keys
      blacklight_config.facet_paginator_class.request_keys
    end

    ##
    # Reset any search parameters that store search context
    # and need to be reset when e.g. constraints change
    # @return [ActionController::Parameters]
    def reset_search_params
      Parameters.sanitize(to_h).except(:page, :counter)
    end
  end
end
