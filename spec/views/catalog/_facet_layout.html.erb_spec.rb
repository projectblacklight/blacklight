# frozen_string_literal: true

RSpec.describe "catalog/facet_layout" do
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

  it "has a facet-specific class" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_selector '.blacklight-some_field'
  end

  it "has a title with a link for a11y" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_selector 'h3', text: 'Some Field'
  end

  it "is collapsable" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_selector 'button.collapsed[data-toggle="collapse"][data-bs-toggle="collapse"][aria-expanded="false"]'
    expect(rendered).to have_selector '.collapse .card-body'
  end

  it "is configured to be open by default" do
    allow(facet_field).to receive_messages(collapse: false)
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_selector 'button[data-toggle="collapse"][data-bs-toggle="collapse"][aria-expanded="true"]'
    expect(rendered).not_to have_selector '.card-header.collapsed'
    expect(rendered).to have_selector '.collapse.show .card-body'
  end
end
