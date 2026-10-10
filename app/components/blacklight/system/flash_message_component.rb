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

      def alert_class(type)
        case type.to_s
        when 'success' then "alert-success theme-success"
        when 'notice'  then "alert-info theme-info"
        when 'alert'   then "alert-warning theme-warning"
        when 'error'   then "alert-danger theme-danger"
        else "alert-#{type} theme-#{type}"
        end
      end
    end
  end
end
