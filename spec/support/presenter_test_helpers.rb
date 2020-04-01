# frozen_string_literal: true

module PresenterTestHelpers
  def controller
    @controller ||= ViewComponent::Base.test_controller.constantize.new.tap { |c| c.request = request }.extend(Rails.application.routes.url_helpers)
  end

  def request
    @request ||= ActionDispatch::TestRequest.create
  end
end
