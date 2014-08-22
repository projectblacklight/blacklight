# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Facets" do
  it "should show a single facet's values" do
    visit catalog_facet_path("language_facet")
    expect(page).to have_selector(".modal-title", :text => "Language")
    expect(page).to have_selector(".facet_select", :text => "Tibetan")
  end
  
  it "should paginate through a facet's values" do
    visit catalog_facet_path("subject_topic_facet")
    expect(page).to have_selector '.facet-values li:first', text: "Japanese drama"
    expect(page).to have_link "A-Z Sort"
    expect(page).to have_selector '.sort_options .active', text: "Numerical Sort"
    within ".modal-footer" do
      click_on "Next »"
    end
    expect(page).to have_selector '.facet-values li:first', text: "Jewish law"
    expect(page).to have_link "« Previous"
  end
  
  it "should be able to change the facet sort" do
    visit catalog_facet_path("subject_topic_facet")
    expect(page).to have_selector '.facet-values li:first', text: "Japanese drama"
    within ".modal-footer" do
      click_on "A-Z Sort"
    end
    expect(page).to have_selector '.facet-values li:first', text: "Accident insurance"
    expect(page).to have_link "Numerical Sort"
    expect(page).to have_selector '.sort_options .active', text: "A-Z Sort"
    
    
  end
end
