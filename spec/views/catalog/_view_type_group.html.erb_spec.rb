# frozen_string_literal: true

RSpec.describe "catalog/_view_type_group" do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:response) { instance_double(Blacklight::Solr::Response, empty?: false) }
  let(:icon_instance) { instance_double(Blacklight::Icon) }

  before do
    allow(view).to receive(:view_label), &:to_s
    allow(Blacklight::Icon).to receive(:new).and_return icon_instance
    allow(icon_instance).to receive(:svg).and_return '<svg></svg>'
    allow(icon_instance).to receive(:options).and_return({})
    allow(view).to receive_messages(how_sort_and_per_page?: true, blacklight_config: blacklight_config)
    controller.request.path_parameters[:action] = 'index'
    assign(:response, response)
  end

  it "does not display the group when there's only one option" do
    allow(response).to receive_messages(empty?: true)
    render partial: 'catalog/view_type_group'
    expect(rendered).to be_empty
  end

  it "displays the group" do
    blacklight_config.configure do |config|
      config.view.delete(:list)
      config.view.a
      config.view.b
      config.view.c
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.btn-group.view-type-group')
    expect(rendered).to have_selector('.view-type-a', text: 'a')
    expect(rendered).to have_selector('.view-type-b', text: 'b')
    expect(rendered).to have_selector('.view-type-c', text: 'c')
  end

  it "sets the current view to 'active'" do
    blacklight_config.configure do |config|
      config.view.delete(:list)
      config.view.a
      config.view.b
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.active', text: 'a')
    expect(rendered).not_to have_selector('.active', text: 'b')
    expect(rendered).to have_selector('.btn', text: 'b')
  end
end
