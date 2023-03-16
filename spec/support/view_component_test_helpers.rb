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
    return vc_test_controller if defined?(vc_test_controller)

    ApplicationController.new.extend(Rails.application.routes.url_helpers)
  end

  # Nokogiri 1.15.0 upgrades the vendored libxml2 from v2.10.4 to v2.11.3
  # libxml2 v2.11.0 introduces a change to parsing HTML href attributes
  # in nokogiri < 1.15, brackets in href attributes are escaped:
  # - <a class="facet-select" rel="nofollow" href="/catalog?f%5Bz%5D%5B%5D=x:1">x:1</a>
  # in nokogiri >= 1.15, brackets in href attributes are not escaped:
  # - <a class="facet-select" rel="nofollow" href="/catalog?f[z][]=x:1">x:1</a>
  # until we can spec a minimum nokogiri version of 1.15.0, we need to see how
  # the installed version parsed the html
  def nokogiri_mediated_href(href)
    start = "<a href=\"".length
    stop = -"\"></a>".length
    Nokogiri::HTML.fragment("<a href=\"#{href}\"></a>").to_s[start...stop]
  end
end
