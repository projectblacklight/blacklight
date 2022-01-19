# frozen_string_literal: true

module Blacklight
  module Deprecations
    module EngineConfiguration
      # rubocop:disable Style/RedundantSelf, Style/HashSyntax
      # @deprecated
      def bookmarks_http_method
        self.blacklight.bookmarks_http_method
      end
      deprecation_deprecate bookmarks_http_method: 'Moved to `blacklight.bookmarks_http_method`'

      # @deprecated
      def bookmarks_http_method=(val)
        self.blacklight.bookmarks_http_method = val
      end
      deprecation_deprecate :'bookmarks_http_method=' => 'Moved to `blacklight.bookmarks_http_method=`'

      # @deprecated
      def email_regexp
        self.blacklight.email_regexp
      end
      deprecation_deprecate email_regexp: 'Moved to `blacklight.email_regexp`'

      # @deprecated
      def email_regexp=(val)
        self.blacklight.email_regexp = val
      end
      deprecation_deprecate :'email_regexp=' => 'Moved to `blacklight.email_regexp=`'

      # @deprecated
      def facet_missing_param
        self.blacklight.facet_missing_param
      end
      deprecation_deprecate facet_missing_param: 'Moved to `blacklight.facet_missing_param`'

      # @deprecated
      def facet_missing_param=(val)
        self.blacklight.facet_missing_param = val
      end
      deprecation_deprecate :'facet_missing_param=' => 'Moved to `blacklight.facet_missing_param=`'

      # @deprecated
      def sms_mappings
        self.blacklight.sms_mappings
      end
      deprecation_deprecate sms_mappings: 'Moved to `blacklight.sms_mappings`'

      # @deprecated
      def sms_mappings=(val)
        self.blacklight.sms_mappings = val
      end
      deprecation_deprecate :'sms_mappings=' => 'Moved to `blacklight.sms_mappings=`'
      # rubocop:enable Style/RedundantSelf, Style/HashSyntax

      def self.deprecate_in(object)
        class << object
          extend Deprecation
          self.deprecation_horizon = 'blacklight 8.0'

          include Blacklight::Deprecations::EngineConfiguration
        end
      end
    end
  end
end
