# frozen_string_literal: true

module ViewComponentCapybaraTestHelpers
  # Work around for https://github.com/teamcapybara/capybara/issues/2466
  def render_inline_to_capybara_node(component)
    Capybara::Node::Simple.new(render_inline(component).to_s)
  end
end
