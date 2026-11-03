# frozen_string_literal: true

RSpec.describe "Open graph metadata" do
  describe "for a page" do
    before do
      visit "/bookmarks"
    end

    it "renders open graph metadata for the page" do
      expect(page).to have_css('meta[property="og:type"][content="website"]', visible: :all)
      expect(page).to have_css('meta[property="og:site_name"][content="Blacklight"]', visible: :all)
      expect(page).to have_css('meta[property="og:title"][content="Bookmarks - Blacklight"]', visible: :all)
      expect(page).to have_css('meta[property="og:url"][content="http://www.example.com/bookmarks"]', visible: :all)
    end
  end

  describe "for a document" do
    before do
      visit "/catalog/2007020969"
    end

    it "renders open graph metadata for the document" do
      expect(page).to have_css('meta[property="og:type"][content="website"]', visible: :all)
      expect(page).to have_css('meta[property="og:site_name"][content="Blacklight"]', visible: :all)
      expect(page).to have_css('meta[property="og:title"][content="\\"Strong Medicine speaks\\""]', visible: :all)
      expect(page).to have_css('meta[property="og:url"][content="http://www.example.com/catalog/2007020969"]', visible: :all)
    end
  end

  describe "for a document with a thumbnail" do
    before do
      config = CatalogController.blacklight_config.deep_copy
      config.show.thumbnail_field = 'thumbnail_path_ss'
      allow(CatalogController).to receive(:blacklight_config).and_return(config)

      visit "/catalog/2008308201"
    end

    it "renders og:image from the thumbnail field" do
      expect(page).to have_css('meta[property="og:image"][content="https://picsum.photos/seed/2008308201/120/90"]', visible: :all)
    end
  end
end
