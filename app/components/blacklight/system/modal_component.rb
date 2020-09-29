# frozen_string_literal: true

module Blacklight
  module System
    class ModalComponent < ViewComponent::Base
      with_content_areas :prefix, :header, :title, :body, :footer
    end
  end
end
