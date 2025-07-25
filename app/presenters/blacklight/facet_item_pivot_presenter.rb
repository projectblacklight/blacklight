# frozen_string_literal: true

module Blacklight
  class FacetItemPivotPresenter < FacetItemPresenter
    ##
    # Check if the query parameters have the given facet field with the
    # given value.
    def selected?
      search_state.filter(facet_config).include?(facet_item)
    end

    def shown?
      selected? || facet_item_presenters.any? { |x| x.try(:shown?) }
    end

    def facet_item_presenters
      return to_enum(:facet_item_presenters) unless block_given?
      return [] unless items

      items.each { |i| yield facet_item_presenter(i) }
    end

    def facet_item_presenter(facet_item)
      view_context.facet_field_presenter(facet_config, {}).item_presenter(facet_item)
    end

    ##
    # Get the displayable version of a facet's value
    #
    # @return [String]
    def label
      label_source = facet_item.respond_to?(:label) ? facet_item.label : facet_item
      if facet_config.helper_method
        view_context.public_send(facet_config.helper_method, label_source)
      else
        item_fq = label_source.respond_to?(:fq) ? label_source.fq : {}
        item_fq = item_fq.symbolize_keys
        label_value = facet_config.pivot.map(&:to_sym).map { |k| item_fq[k] }
        if label_source.respond_to?(:field)
          label_value << value
        else
          label_value.unshift value
        end
        label_value.compact.join(" » ")
      end
    end

    def value
      if facet_item.respond_to? :value
        facet_item.value
      else
        facet_item
      end
    end
  end
end
