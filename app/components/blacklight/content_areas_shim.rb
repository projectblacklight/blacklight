# frozen_string_literal: true

module Blacklight
  # Shim to support ViewComponent v2 slots using the content_areas API for backwards compatibility
  module ContentAreasShim
    # Shim the `with` helper to write content into slots instead
    def with(slot_name, *args, **kwargs, &block)
      Deprecation.warn(Blacklight::ContentAreasShim,
                       'ViewComponents deprecated `with` and it will be removed in ViewComponents 3.0. content_areas. Use slots (https://viewcomponent.org/guide/slots.html) instead.')
      public_send(slot_name, *args, **kwargs, &block)
    end
  end
end
