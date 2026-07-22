# frozen_string_literal: true

require "active_model"

module Blacklight
  # These are data types that blacklight can use to coerce values from the index
  module Types
    @registry = ActiveModel::Type::Registry.new

    class << self
      delegate :lookup, :register, to: :@registry
    end

    class Value
      def self.coerce(input)
        new.cast(input)
      end

      def cast(input)
        if input.is_a?(::Array)
          input.first
        else
          input
        end
      end
    end

    class Array < Value
      def initialize(of: nil, **kwargs)
        @of = of
        @kwargs = kwargs
      end

      def cast(input)
        ::Array.wrap(input).map do |value|
          lookup_type.cast(value)
        end
      end

      private

      def lookup_type
        return Blacklight::Types::Value.new(**@kwargs) if @of.nil?

        @lookup_type ||= Blacklight::Types.lookup(@of, **@kwargs)
      end
    end

    class String < Value
      def cast(input)
        super&.to_s
      end
    end

    class Date < Value
      def cast(input)
        value = super
        return if value.blank?

        begin
          ::Date.parse(value.to_s)
        rescue ArgumentError
          Rails.logger&.info "Unable to parse date: #{value.inspect}"
        end
      end
    end

    class Time < Value
      def cast(input)
        value = super
        return if value.blank?

        begin
          ::Time.parse(value.to_s) # rubocop:disable Rails/TimeZone
        rescue ArgumentError
          Rails.logger&.info "Unable to parse time: #{value.inspect}"
        end
      end
    end

    class Boolean < Value
      def cast(input)
        ActiveModel::Type::Boolean.new.cast(super)
      end
    end

    class JsonValue < Value
      def cast(input)
        value = super

        return value unless value.is_a?(String)

        JSON.parse(value)
      end
    end

    class Selector < Array
      def initialize(by: nil, block: nil, **)
        super(**)
        @by = by
        @block = block
      end

      def cast(input)
        return super.public_send(@by) unless @block

        super.public_send(@by, &@block)
      end
    end

    # rubocop:disable Rails/OutputSafety
    class Html < String
      def cast(input)
        super&.html_safe
      end
    end
    # rubocop:enable Rails/OutputSafety

    register :boolean, Boolean
    register :string, String
    register :date, Date
    register :time, Time
    register :array, Array
    register :json, JsonValue
    register :html, Html
    register :select, Selector
    register :value, Value
  end
end
