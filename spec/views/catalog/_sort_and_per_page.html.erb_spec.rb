# frozen_string_literal: true
require 'spec_helper'

describe "catalog/_sort_and_per_page" do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    blacklight_config.add_results_collection_tool(:sort_widget)
    blacklight_config.add_results_collection_tool(:per_page_widget)
    blacklight_config.add_results_collection_tool(:view_type_group)
    allow(view).to receive_messages(blacklight_config: blacklight_config)
  end

  it "renders the pagination, sort, per page and view type controls" do
    assign(:response, double("Solr::Response", limit_value: 1))
    stub_template "catalog/_paginate_compact.html.erb" => "paginate_compact"
    stub_template "catalog/_sort_widget.html.erb" => "sort_widget"
    stub_template "catalog/_per_page_widget.html.erb" => "per_page_widget"
    stub_template "catalog/_view_type_group.html.erb" => "view_type_group"
    render
    expect(rendered).to match /paginate_compact/
    expect(rendered).to match /sort_widget/
    expect(rendered).to match /per_page_widget/
    expect(rendered).to match /view_type_group/
  end

  it "does not render the pagination controls with bad limit values" do
    assign(:response, double("Solr::Response", limit_value: 0))
    stub_template "catalog/_paginate_compact.html.erb" => "paginate_compact"
    stub_template "catalog/_sort_widget.html.erb" => "sort_widget"
    stub_template "catalog/_per_page_widget.html.erb" => "per_page_widget"
    stub_template "catalog/_view_type_group.html.erb" => "view_type_group"
    render
    expect(rendered).not_to match /paginate_compact/
  end

end
