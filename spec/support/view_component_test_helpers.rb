# frozen_string_literal: true

module ViewComponentTestHelpers
  # Work around for https://github.com/teamcapybara/capybara/issues/2466
  def render_inline_to_capybara_node(component)
    Capybara::Node::Simple.new(render_inline(component).to_s)
  end

  # Work-around for https://github.com/ViewComponent/view_component/pull/1661
  # which made the component test's controller method (more) private. This makes
  # it available so we can set up controller-level state for our tests.
  def controller
    # ViewComponent 2.x
    return super if defined?(super)

    # ViewComponent 3.x
    return __vc_test_helpers_controller if defined?(__vc_test_helpers_controller)

    ApplicationController.new.extend(Rails.application.routes.url_helpers)
  end
end
