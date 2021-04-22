# frozen_string_literal: true

RSpec.describe "catalog/_view_type_group" do
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:response) { instance_double(Blacklight::Solr::Response, empty?: false) }

  before do
    allow(view).to receive(:view_label), &:to_s
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
      config.view.a(icon: :list)
      config.view.b(icon: :list)
      config.view.c(icon: :list)
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.btn-group.view-type-group')
    expect(rendered).to have_selector('.view-type-a', text: 'a')
    within '.view-type-a' do
      expect(rendered).to have_selector 'svg'
    end
    expect(rendered).to have_selector('.view-type-b', text: 'b')
    expect(rendered).to have_selector('.view-type-c', text: 'c')
  end

  it "sets the current view to 'active'" do
    blacklight_config.configure do |config|
      config.view.delete(:list)
      config.view.a(icon: :list)
      config.view.b(icon: :list)
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.active', text: 'a')
    expect(rendered).not_to have_selector('.active', text: 'b')
    expect(rendered).to have_selector('.btn', text: 'b')
  end
end
