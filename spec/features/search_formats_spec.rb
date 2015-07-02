# -*- encoding : utf-8 -*-

require 'spec_helper'

describe "Search Formats" do
  before do
    # Get all the fields from Solr, so the #index documents have the MARC field (to trigger appropriate
    # export formats)
    CatalogController.blacklight_config.default_solr_params[:fl] = '*'
  end

  it "should have an RSS XML response" do
    visit "/catalog.rss?q="
    expect(page).to have_content "Blacklight Search Results"
    doc = Nokogiri::XML(page.body)
    expect(doc.xpath("//item")).to have(10).items
  end

  it "should have an ATOM XML response" do
    visit "/catalog.atom?q="
    expect(page).to have_content "Blacklight Search Results"
    doc = Nokogiri::XML(page.body)
    expect(doc.xpath("//atom:entry", atom: "http://www.w3.org/2005/Atom")).to have(10).entries
  end
end
