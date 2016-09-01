# frozen_string_literal: true
module Blacklight
  module DeprecatedUrlHelperBehavior
    extend Deprecation
    self.deprecation_horizon = 'blacklight 7.x'

    def params_for_search(*args, &block)
      source_params, params_to_merge = case args.length
      when 0
        search_state.params_for_search
      when 1
        search_state.params_for_search(args.first)
      when 2
        Deprecation.warn(Blacklight::DeprecatedUrlHelperBehavior, 'Use Blacklight::SearchState.new(source_params).params_for_search instead')
        Blacklight::SearchState.new(args.first, blacklight_config).params_for_search(args.last)
      else
        raise ArgumentError, "wrong number of arguments (#{args.length} for 0..2)"
      end
    end
    deprecation_deprecate :params_for_search

    def sanitize_search_params(source_params)
      Blacklight::Parameters.sanitize(source_params)
    end
    deprecation_deprecate :sanitize_search_params

    def reset_search_params(source_params)
      Blacklight::SearchState.new(source_params, blacklight_config).send(:reset_search_params)
    end
    deprecation_deprecate :reset_search_params

    def add_facet_params(field, item, source_params = nil)
      if source_params
        Deprecation.warn(Blacklight::DeprecatedUrlHelperBehavior, 'Use Blacklight::SearchState.new(source_params).add_facet_params instead')

        Blacklight::SearchState.new(source_params, blacklight_config).add_facet_params(field, item)
      else
        search_state.add_facet_params(field, item)
      end
    end
    deprecation_deprecate :add_facet_params

    def remove_facet_params(field, item, source_params = nil)
      if source_params
        Deprecation.warn(Blacklight::DeprecatedUrlHelperBehavior, 'Use Blacklight::SearchState.new(source_params).remove_facet_params instead')

        Blacklight::SearchState.new(source_params, blacklight_config).remove_facet_params(field, item)
      else
        search_state.remove_facet_params(field, item)
      end
    end
    deprecation_deprecate :remove_facet_params

    delegate :add_facet_params_and_redirect, to: :search_state
    deprecation_deprecate :add_facet_params_and_redirect
  end
end
