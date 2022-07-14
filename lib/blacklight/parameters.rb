# frozen_string_literal: true

module Blacklight
  class Parameters
    ##
    # Sanitize the search parameters by removing unnecessary parameters
    # from the provided parameters.
    # @param [Hash] params parameters
    # rubocop:disable Style/CollectionCompact can be removed when we drop Rails 6.0 support
    def self.sanitize params
      params.reject { |_k, v| v.nil? }
            .except(:action, :controller, :id, :commit, :utf8)
    end
    # rubocop:enable Style/CollectionCompact

    # rubocop:disable Naming/MethodParameterName
    # Merge two Rails strong_params-style permissions into a single list of permitted parameters,
    # deep-merging complex values as needed.
    # @param [Array<Symbol, Hash>] a
    # @param [Array<Symbol, Hash>] b
    # @return [Array<Symbol, Hash>]
    def self.deep_merge_permitted_params(a, b)
      a = [a] if a.is_a? Hash
      b = [b] if b.is_a? Hash

      complex_params_from_a, scalar_params_from_a = a.flatten.uniq.partition { |x| x.is_a? Hash }
      complex_params_from_a = complex_params_from_a.inject({}) { |tmp, h| _deep_merge_permitted_param_hashes(h, tmp) }
      complex_params_from_b, scalar_params_from_b = b.flatten.uniq.partition { |x| x.is_a? Hash }
      complex_params_from_b = complex_params_from_b.inject({}) { |tmp, h| _deep_merge_permitted_param_hashes(h, tmp) }

      (scalar_params_from_a + scalar_params_from_b + [_deep_merge_permitted_param_hashes(complex_params_from_a, complex_params_from_b)]).reject(&:blank?).uniq
    end

    private_class_method def self._deep_merge_permitted_param_hashes(h1, h2)
      h1.merge(h2) do |_key, old_value, new_value|
        if (old_value.is_a?(Hash) && old_value.empty?) || (new_value.is_a?(Hash) && new_value.empty?)
          {}
        elsif old_value.is_a?(Hash) && new_value.is_a?(Hash)
          _deep_merge_permitted_param_hashes(old_value, new_value)
        elsif old_value.is_a?(Array) || new_value.is_a?(Array)
          deep_merge_permitted_params(old_value, new_value)
        else
          new_value
        end
      end
    end
    # rubocop:enable Naming/MethodParameterName

    attr_reader :params, :search_state

    delegate :blacklight_config, :filter_fields, to: :search_state

    def initialize(params, search_state)
      @params = params.is_a?(Hash) ? params.with_indifferent_access : params
      @search_state = search_state
    end

    # @param [Hash] params with unknown structure (not declared in the blacklight config or filters) stripped out
    def permit_search_params
      # if the parameters were generated internally, we can (probably) trust that they're fine
      return params unless params.is_a?(ActionController::Parameters)

      # if the parameters were permitted already, we should be able to trust them
      return params if params.permitted?

      permitted_params = filter_fields.inject(blacklight_config.search_state_fields) do |allowlist, filter|
        Blacklight::Parameters.deep_merge_permitted_params(allowlist, filter.permitted_params)
      end

      deep_unmangle_params!(params, permitted_params)

      if blacklight_config.filter_search_state_fields
        if Rails.application.config.action_controller.action_on_unpermitted_parameters == :raise
          # Rails will blow up if we don't permit all parameters. We're just trying to filter out non-search parameters, so
          # we'll slice the params first so it doesn't blow up... this does mean we'll lose the opportunity to use
          # these parameters later, but if the alterantive is an exception, maybe this is better.
          top_level_permitted_params = permitted_params.flat_map { |p| p.is_a?(Hash) ? p.keys : p }
          params.slice(*top_level_permitted_params).permit(*permitted_params)
        else
          params.permit(*permitted_params)
        end
      else
        params.deep_dup.permit!
      end
    end

    private

    # Facebook's crawler turns array query parameters into a hash with numeric keys. Once we know
    # the expected parameter structure, we can unmangle those parameters to match our expected values.
    def deep_unmangle_params!(params, permitted_params)
      permitted_params.select { |p| p.is_a?(Hash) }.each do |permission|
        permission.each do |key, permitted_value|
          next unless params[key].is_a?(ActionController::Parameters)

          if permitted_value.is_a?(Hash)
            deep_unmangle_params!(params[key], [permitted_value])
          elsif permitted_value.is_a?(Array) && permitted_value.empty? && params[key]&.keys&.all? { |k| k.to_s =~ /\A\d+\z/ }
            params[key] = params[key].values
          end
        end
      end
    end
  end
end
