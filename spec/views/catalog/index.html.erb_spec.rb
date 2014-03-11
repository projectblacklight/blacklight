require 'spec_helper'

describe "catalog/index.html.erb" do

  describe "with no search parameters" do
    before do
      view.stub(:has_search_parameters?).and_return(false)
      view.stub(:blacklight_config).and_return(Blacklight::Configuration.new)
    end
    it "should render the sidebar and content panes" do
      render
      expect(rendered).to match /id="sidebar"/
      expect(rendered).to match /id="content"/
    end

    it "should render the search_sidebar partial " do
      stub_template "catalog/_search_sidebar.html.erb" => "sidebar_content"
      render
      expect(rendered).to match /sidebar_content/
    end
  end

  describe "with search parameters" do
    before do
      view.stub(:has_search_parameters?).and_return(true)
      stub_template "catalog/_results_pagination.html.erb" => ""
      stub_template "catalog/_search_header.html.erb" => "header_content"

      view.stub(:blacklight_config).and_return(Blacklight::Configuration.new)
      view.stub(:render_opensearch_response_metadata).and_return("")
      assign(:response, double(:empty? => true))
    end
    it "should render the search_header partial " do
      render
      expect(rendered).to match /header_content/
    end
  end
end
