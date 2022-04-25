# frozen_string_literal: true

module Blacklight
  module Deprecations
    module SearchStateNormalization
      extend ActiveSupport::Concern

      class_methods do
        def facet_params_need_normalization(facet_params)
          Deprecation.warn(self, 'Calling `facet_params_need_normalization` on the Blacklight::SearchState ' \
          'class is deprecated and will be removed in Blacklight 8. Delegate to #needs_normalization?(value_params) on the ' \
          'filter fields of the search state object.')

          facet_params.is_a?(Hash) && facet_params.values.any? { |x| x.is_a?(Hash) }
        end

        def normalize_facet_params(facet_params)
          Deprecation.warn(self, 'Calling `normalize_facet_params` on the Blacklight::SearchState ' \
          'class is deprecated and will be removed in Blacklight 8. Delegate to #normalize(value_params) on the ' \
          'filter fields of the search state object.')

          facet_params.transform_values { |value| value.is_a?(Hash) ? value.values : value }
        end

        def normalize_params(untrusted_params = {})
          Deprecation.warn(self, 'Calling `normalize_params` on the Blacklight::SearchState ' \
          'class is deprecated and will be removed in Blacklight 8. Call #normalize_params on the ' \
          'search state object.')
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
          params[:f] = normalize_facet_params(params[:f]) if facet_params_need_normalization(params[:f])
          params[:f_inclusive] = normalize_facet_params(params[:f_inclusive]) if facet_params_need_normalization(params[:f_inclusive])

          params
        end
      end
    end
  end
end
