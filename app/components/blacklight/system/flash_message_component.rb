# frozen_string_literal: true

module Blacklight
  module System
    class FlashMessageComponent < Blacklight::Component
      renders_one :message

      with_collection_parameter :message

      def initialize(type:, message: nil)
        @message = message
        @classes = alert_class(type)
      end

      def before_render
        with_message { @message } if @message
      end

      # Bootstrap 4 requires the span, but Bootstrap 5 should not have it.
      # See https://getbootstrap.com/docs/4.6/components/alerts/#dismissing
      #     https://getbootstrap.com/docs/5.1/components/alerts/#dismissing
      def button_contents
        return if helpers.controller.blacklight_config.bootstrap_version == 5

        tag.span '&times;'.html_safe, aria: { hidden: true }
      end

      def alert_class(type)
        case type.to_s
        when 'success' then "alert-success"
        when 'notice'  then "alert-info"
        when 'alert'   then "alert-warning"
        when 'error'   then "alert-danger"
        else "alert-#{type}"
        end
      end
    end
  end
end
