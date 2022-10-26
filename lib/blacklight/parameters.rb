# frozen_string_literal: true

require 'hashdiff'

module Blacklight
  class Parameters
    extend Deprecation

    ##
    # Sanitize the search parameters by removing unnecessary parameters
    # from the provided parameters.
    # @param [Hash] params parameters
    def self.sanitize params
      # TODO: switch to .compact when we drop Rails 6.0 support.
      # See https://github.com/rubocop/rubocop/issues/11066
      params.reject { |_k, v| v.nil? } # rubocop:disable Style/CollectionCompact
            .except(:action, :controller, :id, :commit, :utf8)
    end

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

      # TODO: switch to .compact_blank when we drop Rails 6.0 support.
      (scalar_params_from_a + scalar_params_from_b + [_deep_merge_permitted_param_hashes(complex_params_from_a, complex_params_from_b)]).reject(&:blank?).uniq # rubocop:disable Rails/CompactBlank
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
        params.permit(*permitted_params)
      else
        warn_about_deprecated_parameter_handling(params, permitted_params)
        params.deep_dup.permit!
      end
    end

    private

    def warn_about_deprecated_parameter_handling(params, permitted_params)
      diff = Hashdiff.diff(params.to_unsafe_h, params.permit(*permitted_params).to_h)
      return if diff.empty?

      Deprecation.warn(Blacklight::Parameters, "Blacklight 8 will filter out non-search parameter, including: #{diff.map { |_op, key, *| key }.to_sentence}")
    end

    # Facebook's crawler turns array query parameters into a hash with numeric keys. Once we know
    # the expected parameter structure, we can unmangle those parameters to match our expected values.
    def deep_unmangle_params!(params, permitted_params)
      permitted_params.select { |p| p.is_a?(Hash) }.each do |permission|
        permission.each do |key, permitted_value|
          if params[key].is_a?(ActionController::Parameters) && permitted_value.is_a?(Hash)
            deep_unmangle_params!(params[key], [permitted_value])
          elsif permitted_value.is_a?(Array) && permitted_value.empty?
            if params[key].is_a?(ActionController::Parameters) && params[key]&.keys&.all? { |k| k.to_s =~ /\A\d+\z/ }
              params[key] = params[key].values
            elsif params[key].is_a?(String)
              params[key] = Array(params[key])
            end
          end
        end
      end
    end
  end
end
