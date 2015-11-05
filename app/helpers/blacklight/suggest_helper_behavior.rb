module Blacklight
  module SuggestHelperBehavior
    ##
    # @return [Boolean] should autocomplete be enabled in the UI
    def autocomplete_enabled?
      blacklight_config.autocomplete_enabled.present? &&
        blacklight_config.autocomplete_path.present?
    end
  end
end
