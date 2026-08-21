# frozen_string_literal: true

module Blacklight
  module Rendering
    class Join < AbstractStep
      def render
        options = config.separator_options || {}
        if values.one? || values.none?
          next_step(values.first)
        elsif !html?
          next_step(values.to_sentence(options))
        else
          next_step(values.map { |x| x.html_safe? ? x : html_escape(x) }.to_sentence(options).html_safe)
        end
      end

      private

      def html_escape(*)
        ERB::Util.html_escape(*)
      end
    end
  end
end
