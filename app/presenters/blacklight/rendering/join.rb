# frozen_string_literal: true

module Blacklight
  module Rendering
    class Join < AbstractStep
      def render
        options = config.separator_options || {}

        if join? && html? && values.many?
          # Each value is escaped unless already html_safe, and the connectors come from config/i18n, so the result is safe
          # rubocop:disable-next Rails/OutputSafety
          next_step(values.map { |x| x.html_safe? ? x : html_escape(x) }.to_sentence(options).html_safe)
        else
          next_step(values)
        end
      end

      private

      def html_escape(*)
        ERB::Util.html_escape(*)
      end

      # @return [Boolean]
      def join?
        options[:join] || config.join || config.separator_options
      end
    end
  end
end
