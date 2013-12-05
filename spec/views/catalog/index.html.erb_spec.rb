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

  it "should render the search_header partial " do
    stub_template "catalog/_results_pagination.html.erb" => ""
    stub_template "catalog/_search_header.html.erb" => "header_content"

    view.stub(:blacklight_config).and_return(Blacklight::Configuration.new)
    view.stub(:has_search_parameters?).and_return(true)
    view.stub(:render_opensearch_response_metadata).and_return("")
    view.stub(:response_has_no_search_results?).and_return(true)
    render
    expect(rendered).to match /header_content/
  end
end