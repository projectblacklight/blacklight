# frozen_string_literal: true

module Blacklight
  class SkipLinkComponent < Blacklight::Component
    def link_to_search
      link_to t('blacklight.skip_links.search_field'), search_id, class: link_classes
    end

    def link_to_main
      link_to t('blacklight.skip_links.main_content'), '#main-container', class: link_classes
    end

    def search_id
      return '#search_field' if helpers.blacklight_config.search_fields.values.many? { |field_def| helpers.should_render_field?(field_def) }

      '#q'
    end

    def link_classes
      'visually-hidden-focusable rounded-bottom py-2 px-3'
    end
  end
end
