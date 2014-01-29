require 'spec_helper'

describe "catalog/_view_type_group" do

  let :blacklight_config do
    Blacklight::Configuration.new
  end

  before do
    view.stub(blacklight_config: blacklight_config)
  end

  it "should not display the group when there's only one option" do
    blacklight_config.stub document_index_view_types: ['a']
    render partial: 'catalog/view_type_group'
    expect(rendered).to be_empty
  end

  it "should display the group" do
    blacklight_config.stub document_index_view_types: ['a', 'b', 'c']
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.btn-group.view-type-group')
    expect(rendered).to have_selector('.view-type-a', :text => 'A')
    expect(rendered).to have_selector('.view-type-b', :text => 'B')
    expect(rendered).to have_selector('.view-type-c', :text => 'C')
  end


  it "should set the current view to 'active'" do
    blacklight_config.stub document_index_view_types: ['a', 'b']
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.active', :text => 'A')
    expect(rendered).to_not have_selector('.active', :text => 'B')
    expect(rendered).to have_selector('.btn', :text => 'B')
  end

end