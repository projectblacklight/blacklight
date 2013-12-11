require 'spec_helper'

describe "Facets" do
  it "should show a single facet's values" do
    visit catalog_facet_path("language_facet")
    expect(page).to have_selector(".modal-title", :text => "Language")
    expect(page).to have_selector(".facet_select", :text => "Tibetan")
  end
end