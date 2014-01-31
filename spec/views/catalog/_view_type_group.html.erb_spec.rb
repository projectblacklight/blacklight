require 'spec_helper'

describe "catalog/_view_type_group" do

  let :blacklight_config do
    Blacklight::Configuration.new
  end

  before do
    view.stub(blacklight_config: blacklight_config)
  end

  it "should not display the group when there's only one option" do
    render partial: 'catalog/view_type_group'
    expect(rendered).to be_empty
  end

  it "should display the group" do
    blacklight_config.configure do |config|
      config.view.delete(:list)
      config.view.a 
      config.view.b
      config.view.c
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.btn-group.view-type-group')
    expect(rendered).to have_selector('.view-type-a', :text => 'A')
    expect(rendered).to have_selector('.view-type-b', :text => 'B')
    expect(rendered).to have_selector('.view-type-c', :text => 'C')
  end


  it "should set the current view to 'active'" do
    blacklight_config.configure do |config|
      config.view.delete(:list)
      config.view.a 
      config.view.b
    end
    render partial: 'catalog/view_type_group'
    expect(rendered).to have_selector('.active', :text => 'A')
    expect(rendered).to_not have_selector('.active', :text => 'B')
    expect(rendered).to have_selector('.btn', :text => 'B')
  end

end