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
    expect(rendered).to have_css '.blacklight-some_field'
  end

  it "has a title with a link for a11y" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_css 'h3', text: 'Some Field'
  end

  it "is collapsable" do
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_css 'button.collapsed[data-toggle="collapse"][data-bs-toggle="collapse"][aria-expanded="false"]'
    expect(rendered).to have_css '.collapse .accordion-body'
  end

  it "is configured to be open by default" do
    allow(facet_field).to receive_messages(collapse: false)
    render partial: 'catalog/facet_layout', locals: { facet_field: facet_field }
    expect(rendered).to have_css 'button[data-toggle="collapse"][data-bs-toggle="collapse"][aria-expanded="true"]'
    expect(rendered).to have_no_css '.accordion-header.collapsed'
    expect(rendered).to have_css '.collapse.show .accordion-body'
  end
end
