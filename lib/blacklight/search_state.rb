# frozen_string_literal: true

require 'blacklight/search_state/filter_field'

module Blacklight
  # This class encapsulates the search state as represented by the query
  # parameters namely: :f, :q, :page, :per_page and, :sort
  class SearchState
    extend Deprecation

    attr_reader :blacklight_config # Must be called blacklight_config, because Blacklight::Facet calls blacklight_config.
    attr_reader :params

    # This method is never accessed in this class, but may be used by subclasses that need
    # to access the url_helpers
    attr_reader :controller

    delegate :facet_configuration_for_field, to: :blacklight_config

    # @param [ActionController::Parameters] params
    # @param [Blacklight::Config] blacklight_config
    # @param [ApplicationController] controller used for the routing helpers
    def initialize(params, blacklight_config, controller = nil)
      @params = self.class.normalize_params(params)
      @blacklight_config = blacklight_config
      @controller = controller
    end

    def self.normalize_params(untrusted_params = {})
      params = untrusted_params

      if params.respond_to?(:to_unsafe_h)
        # This is the typical (not-ActionView::TestCase) code path.
        params = params.to_unsafe_h
        # In Rails 5 to_unsafe_h returns a HashWithIndifferentAccess, in Rails 4 it returns Hash
        params = params.with_indifferent_access if params.instance_of? Hash
      elsif params.is_a? Hash
        # This is an ActionView::TestCase workaround for Rails 4.2.
        params = params.dup.with_indifferent_access
      else
        params = params.dup.to_h.with_indifferent_access
      end

      # Normalize facet parameters mangled by facebook
      if params[:f].is_a?(Hash) && params[:f].values.any? { |x| x.is_a?(Hash) }
        params[:f] = params[:f].transform_values do |value|
          value.is_a?(Hash) ? value.values : value
        end
      end

      params
    end

    def to_hash
      @params.deep_dup
    end
    alias to_h to_hash

    def to_unsafe_h
      Deprecation.warn(self.class, 'Use SearchState#to_h instead of SearchState#to_unsafe_h')
      to_hash
    end

    def method_missing(method_name, *arguments, &block)
      if @params.respond_to?(method_name)
        Deprecation.warn(self.class, "Calling `#{method_name}` on Blacklight::SearchState " \
          'is deprecated and will be removed in Blacklight 8. Call #to_h first if you ' \
          ' need to use hash methods (or, preferably, use your own SearchState implementation)')
        @params.public_send(method_name, *arguments, &block)
      else
        super
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      @params.respond_to?(method_name, include_private) || super
    end

    # Tiny shim to make it easier to migrate raw params access to using this class
    delegate :[], to: :params
    deprecation_deprecate :[]

    def has_constraints?
      Deprecation.silence(Blacklight::SearchState) do
        !(query_param.blank? && filter_params.blank? && filters.blank?)
      end
    end

    def query_param
      params[:q]
    end

    def filter_params
      params[:f] || {}
    end
    deprecation_deprecate filter_params: 'Use #filters instead'

    # @return [Blacklight::SearchState]
    def reset(params = nil)
      self.class.new(params || ActionController::Parameters.new, blacklight_config, controller)
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
      if respond_to?(:blacklight_config) &&
          blacklight_config.show.route &&
          (!doc.respond_to?(:to_model) || doc.to_model.is_a?(SolrDocument))
        route = blacklight_config.show.route.merge(action: :show, id: doc).merge(options)
        route[:controller] = params[:controller] if route[:controller] == :current
        route
      else
        doc
      end
    end

    def remove_query_params
      p = reset_search_params
      p.delete(:q)
      p
    end

    def filters
      @filters ||= blacklight_config.facet_fields.each_value.map do |value|
        f = filter(value)

        f if f.any?
      end.compact
    end

    def filter(field_key_or_field)
      field = field_key_or_field if field_key_or_field.is_a? Blacklight::Configuration::Field
      field ||= blacklight_config.facet_fields[field_key_or_field]
      field ||= Blacklight::Configuration::NullField.new(key: field_key_or_field)

      (field.filter_class || FilterField).new(field, self)
    end

    # adds the value and/or field to params[:f]
    # Does NOT remove request keys and otherwise ensure that the hash
    # is suitable for a redirect. See
    # add_facet_params_and_redirect
    def add_facet_params(field, item)
      filter(field).add(item).params
    end
    deprecation_deprecate add_facet_params: 'Use filter(field).add(item) instead'

    # Used in catalog/facet action, facets.rb view, for a click
    # on a facet value. Add on the facet params to existing
    # search constraints. Remove any paginator-specific request
    # params, or other request params that should be removed
    # for a 'fresh' display.
    # Change the action to 'index' to send them back to
    # catalog/index with their new facet choice.
    def add_facet_params_and_redirect(field, item)
      new_params = Deprecation.silence(self.class) do
        add_facet_params(field, item)
      end

      # Delete any request params from facet-specific action, needed
      # to redir to index action properly.
      request_keys = blacklight_config.facet_paginator_class.request_keys
      new_params.extract!(*request_keys.values)

      new_params
    end

    # copies the current params (or whatever is passed in as the 3rd arg)
    # removes the field value from params[:f]
    # removes the field if there are no more values in params[:f][field]
    # removes additional params (page, id, etc..)
    # @param [String] field
    # @param [String] item
    def remove_facet_params(field, item)
      filter(field).remove(item).params
    end
    deprecation_deprecate remove_facet_params: 'Use filter(field).remove(item) instead'

    def has_facet?(config, value: nil)
      if value
        filter(config).include?(value)
      else
        filter(config).any?
      end
    end
    deprecation_deprecate has_facet?: 'Use filter(field).include?(value) or .any? instead'

    # Merge the source params with the params_to_merge hash
    # @param [Hash] params_to_merge to merge into above
    # @return [ActionController::Parameters] the current search parameters after being sanitized by Blacklight::Parameters.sanitize
    # @yield [params] The merged parameters hash before being sanitized
    def params_for_search(params_to_merge = {})
      # params hash we'll return
      my_params = params.dup.merge(self.class.new(params_to_merge, blacklight_config, controller))

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
      Parameters.sanitize(params).except(:page, :counter)
    end
  end
end
