# frozen_string_literal: true

describe "Search Formats" do
  it "has an RSS XML response" do
    visit "/catalog.rss?q="
    expect(page).to have_content "Blacklight Search Results"
    doc = Nokogiri::XML(page.body)
    expect(doc.xpath("//item")).to have(10).items
  end

  it "has an ATOM XML response" do
    visit "/catalog.atom?q="
    expect(page).to have_content "Blacklight Search Results"
    doc = Nokogiri::XML(page.body)
    expect(doc.xpath("//atom:entry", atom: "http://www.w3.org/2005/Atom")).to have(10).entries
  end
end
