# frozen_string_literal: true

module Blacklight
  class SkipLinkComponent < Blacklight::Component
    def link_to_search
      render skip_link_item_component.new(text: t('blacklight.skip_links.search_field'), href: search_id)
    end

    def link_to_main
      render skip_link_item_component.new(text: t('blacklight.skip_links.main_content'), href: '#main-container')
    end

    def search_id
      return '#search_field' if helpers.blacklight_config.search_fields.values.many? { |field_def| helpers.should_render_field?(field_def) }

      '#q'
    end

    delegate :blacklight_config, to: :helpers
    delegate :skip_link_item_component, to: :blacklight_config

    def link_classes
      Blacklight.deprecation.warn("Use SkipLinkItemComponent instead")
      'visually-hidden-focusable rounded-bottom py-2 px-3'
    end
  end
end
