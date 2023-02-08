# frozen_string_literal: true

module Blacklight
  module Gallery
    class DocumentComponent < Blacklight::DocumentComponent
      def call
        "TEST#{@presenter.heading}"
      end
    end
  end
end
