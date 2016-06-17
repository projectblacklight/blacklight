module Blacklight
  # Render a value (or array of values) from a field
  # Renders itemprop and joins multiple values with separator_options
  class ValueRenderer
    include ActionView::Helpers::TagHelper
    # @param [Array<String,Fixnum>] values list of values to display
    # @param [Blacklight::Configuration::Field] field_config field configuration
    def initialize(values, field_config = nil)
      @values = recode_values(values)
      @field_config = field_config
    end

    attr_reader :values, :field_config

    # @return [String]
    # TODO: Move this out to field_presenter, so that ValueRenderer doesn't need TagHelper .
    def render
      if field_config and field_config.itemprop
        @values = values.map { |x| content_tag :span, x, :itemprop => field_config.itemprop }
      end

      render_values(@values, field_config)
    end

    private

      ##
      # Render a fields values as a string
      # @param [Array] values to display
      # @return [String]
      def render_values(values, field_config = nil)
        options = {}
        options = field_config.separator_options if field_config && field_config.separator_options

        values.map { |x| html_escape(x) }.to_sentence(options).html_safe
      end

      # @param [Array] values the values to display
      # @return [Array] an array with all strings converted to UTF-8
      def recode_values(values)
        values.map do |value|
          if value.respond_to?(:encoding) && value.encoding != Encoding::UTF_8
            Rails.logger.warn "Found a non utf-8 value in Blacklight::DocumentPresenter. \"#{value}\" Encoding is #{value.encoding}"
            value.dup.force_encoding('UTF-8')
          else
            value
          end
        end
      end

      def html_escape(*args)
        ERB::Util.html_escape(*args)
      end
  end
end
