# frozen_string_literal: true

module Blacklight
  module Rendering
    class Terminator < AbstractStep
      def render
        Array.wrap values
      end
    end
  end
end
