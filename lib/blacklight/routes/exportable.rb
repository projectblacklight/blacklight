# frozen_string_literal: true
module Blacklight
  module Routes
    class Exportable
      def initialize(defaults = {})
        @defaults = defaults
      end

      def call(mapper, _options = {})
        mapper.member do
          mapper.match 'email', via: [:get, :post]
          mapper.match 'sms', via: [:get, :post]
          mapper.get 'citation'
        end

        mapper.collection do
          mapper.match 'email', via: [:get, :post]
          mapper.match 'sms', via: [:get, :post]
          mapper.get 'citation'
        end
      end
    end
  end
end
