# frozen_string_literal: true

module Blacklight
  module System
    class ModalComponent < ViewComponent::Base
      renders_one :prefix
      renders_one :header
      renders_one :title
      renders_one :body
      renders_one :footer
    end
  end
end
