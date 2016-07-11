# frozen_string_literal: true
require 'spec_helper'

describe "catalog/_view_type_group" do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(view).to receive(:view_label) do |view|
      view.to_s
    end
    allow(view).to receive_messages(how_sort_and_per_page?: true, blacklight_config: blacklight_config)
    controller.request.path_parameters[:action] = 'index'
  end

  it "does not display the group when there's only one option" do
    assign(:response, [])
    render partial: 'catalog/view_type_group'
    expect(rendered).to be_empty
  end

  it "displays the group" do
    assign(:response, [double])
    blacklight_config.configure do |config|
      config.view.delete(:list)
      config.view.a
      config.view.b
      config.view.c
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.btn-group.view-type-group')
    expect(rendered).to have_selector('.view-type-a', :text => 'a')
    expect(rendered).to have_selector('.view-type-b', :text => 'b')
    expect(rendered).to have_selector('.view-type-c', :text => 'c')
  end

  it "sets the current view to 'active'" do
    assign(:response, [double])
    blacklight_config.configure do |config|
      config.view.delete(:list)
      config.view.a
      config.view.b
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.active', :text => 'a')
    expect(rendered).to_not have_selector('.active', :text => 'b')
    expect(rendered).to have_selector('.btn', :text => 'b')
  end
end
