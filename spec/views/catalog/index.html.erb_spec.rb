require 'spec_helper'

describe "catalog/index.html.erb" do
  it "should render the sidebar and content panes" do
    view.stub(:blacklight_config).and_return(Blacklight::Configuration.new)
    render
    expect(rendered).to match /id="sidebar"/
    expect(rendered).to match /id="content"/
  end

  it "should render the search_sidebar partial " do
    stub_template "catalog/_search_sidebar.html.erb" => "sidebar_content"

    view.stub(:blacklight_config).and_return(Blacklight::Configuration.new)
    render
    expect(rendered).to match /sidebar_content/
  end
end