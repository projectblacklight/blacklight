# frozen_string_literal: true

module Blacklight
  module Rendering
    class Join < AbstractStep
      def render
        options = config.separator_options || {}

        if join? && html? && values.many?
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
