require 'spec_helper'

describe 'catalog/facet.html.erb' do
  let(:display_facet) { double }
  let(:blacklight_config) { Blacklight::Configuration.new }
  before :each do
    blacklight_config.add_facet_field 'xyz', label: "Facet title"
    view.stub(:blacklight_config).and_return(blacklight_config)
    stub_template 'catalog/_facet_pagination.html.erb' => 'pagination'
    assign :facet, blacklight_config.facet_fields['xyz']
    assign :display_facet, display_facet
  end

  it "should have the facet title" do
    view.stub(:render_facet_limit)
    render
    expect(rendered).to have_selector 'h3', text: "Facet title"
  end

  it "should render facet pagination" do
    view.stub(:render_facet_limit)
    render
    expect(rendered).to have_content 'pagination'
  end

  it "should render the facet limit" do
    view.should_receive(:render_facet_limit).with(display_facet, layout: false)
    render
  end
end