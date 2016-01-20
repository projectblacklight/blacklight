# frozen_string_literal: true
require 'spec_helper'

describe "catalog/constraints" do
  let :blacklight_config do
    Blacklight::Configuration.new do |config|
      config.view.xyz
    end
  end

  it "should render nothing if no constraints are set" do
    allow(view).to receive_messages(query_has_constraints?: false)
    render partial: "catalog/constraints"
    expect(rendered).to be_empty
  end

  it "should render a start over link" do
    allow(view).to receive(:search_action_path).with({}).and_return('http://xyz')
    allow(view).to receive_messages(query_has_constraints?: true)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    render partial: "catalog/constraints"
    expect(rendered).to have_selector("#startOverLink")
    expect(rendered).to have_link("Start Over", :href => 'http://xyz')
  end

  it "should render a start over link with the current view type" do
    allow(view).to receive(:search_action_path).with(view: :xyz).and_return('http://xyz?view=xyz')
    allow(view).to receive_messages(query_has_constraints?: true)
    params[:view] = 'xyz'
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    render partial: "catalog/constraints"
    expect(rendered).to have_selector("#startOverLink")
    expect(rendered).to have_link("Start Over", :href => 'http://xyz?view=xyz')
  end

end
