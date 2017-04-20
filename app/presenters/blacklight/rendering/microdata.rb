module Blacklight
  module Rendering
    class Microdata < AbstractStep
      include ActionView::Helpers::TagHelper
      def render
        return next_step(values) unless config.itemprop
        next_step(values.map { |x| itemprop(x, config.itemprop) })
      end

      private

      def itemprop(val, itemprop)
        content_tag :span, val, itemprop: itemprop
      end
    end
  end
end
