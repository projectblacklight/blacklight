# frozen_string_literal: true
require 'spec_helper'

describe "catalog/facet_layout" do

  let :blacklight_config do
    Blacklight::Configuration.new do |config|
      config.facet_fields[facet_field.field] = facet_field
    end
  end

  let :facet_field do
    Blacklight::Configuration::FacetField.new(field: 'some_field').normalize!
  end

  before do
    allow(view).to receive_messages(blacklight_config: blacklight_config)
  end

  it "should have a facet-specific class" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_selector '.blacklight-some_field' 
  end

  it "should have a title with a link for a11y" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_selector 'h3 a', text: 'Some Field'
  end

  it "should be collapsable" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_selector '.panel-heading.collapsed'
    expect(rendered).to have_selector '.collapse .panel-body'
  end

  it "should be configured to be open by default" do
    allow(facet_field).to receive_messages(collapse: false)
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to_not have_selector '.panel-heading.collapsed'
    expect(rendered).to have_selector '.in .panel-body'

  end


end