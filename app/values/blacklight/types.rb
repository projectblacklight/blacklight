module Blacklight
  # These are data types that blacklight can use to coerce values from the index
  module Types
    class Array
      def self.coerce(input)
        ::Array.wrap(input)
      end
    end

    class String
      def self.coerce(input)
        ::Array.wrap(input).first
      end
    end

    class Date
      def self.coerce(input)
        field = String.coerce(input)
        return if field.blank?
        begin
          ::Date.parse(field)
        rescue ArgumentError
          Rails.logger.info "Unable to parse date: #{field.first.inspect}"
        end
      end
    end
  end
end
