# frozen_string_literal: true

module Blacklight
  class SkipLinkComponent < Blacklight::Component
    def link_to_search
      link_to t('blacklight.skip_links.search_field'), '#search_field', class: link_classes
    end

    def link_to_main
      link_to t('blacklight.skip_links.main_content'), '#main-container', class: link_classes
    end

    def link_classes
      'd-inline-flex p-2 m-1'
    end
  end
end
