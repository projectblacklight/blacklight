# frozen_string_literal: true

module Blacklight
  module System
    class FlashMessageComponent < ViewComponent::Base
      with_collection_parameter :message

      def initialize(message:, type:)
        @message = message
        @classes = alert_class(type)
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
