# frozen_string_literal: true

RSpec.describe "Bookmarks" do
  describe "navigating from the homepage" do
    it "has a link to the history page" do
      sign_in 'user1'
      visit root_path
      click_on 'Bookmarks'
      expect(page).to have_content 'You have no bookmarks'
    end
  end

  describe "when bookmark counter is not rendered" do
    before do
      allow(CatalogController).to receive(:render_bookmarks_control?).and_return(false)
    end

    it 'adds bookmark without raising an alert', :js do
      visit solr_document_path('2007020969')
      check 'Bookmark'
      visit bookmarks_path
      expect(page).to have_css('input[type="checkbox"][checked]')
    end
  end

  it "clears bookmarks" do
    visit solr_document_path('2007020969')
    click_on 'Bookmark'
    click_on 'Bookmarks'
    click_on 'Clear Bookmarks'
    expect(page).to have_content 'Cleared your bookmarks.'
    expect(page).to have_content 'You have no bookmarks'
  end

  it "add and remove bookmarks from search results" do
    sign_in 'user1'
    visit root_path
    fill_in "q", with: 'Sumadhvavijayaḥ'
    click_on 'search'
    click_on 'Bookmark'
    expect(page).to have_content 'Successfully added bookmark.'
    fill_in "q", with: 'Sumadhvavijayaḥ'
    click_on 'search'
    click_on 'Remove bookmark'
    expect(page).to have_content 'Successfully removed bookmark.'
  end

  it "adds and delete bookmarks from the show page" do
    sign_in 'user1'
    visit solr_document_path('2007020969')
    click_on 'Bookmark'
    click_on 'Remove bookmark'
    expect(page).to have_content 'Successfully removed bookmark.'
  end

  it 'shows bookmarks as checkboxes', :js do
    visit solr_document_path('2007020969')
    check 'Bookmark'

    visit solr_document_path('2007020969')
    expect(page).to have_css('input[type="checkbox"][checked]')
    uncheck 'In Bookmarks'
  end

  it "adds bookmarks after a user logs in" do
    visit solr_document_path('2007020969')
    click_on 'Bookmark'
    sign_in 'user1'
    visit bookmarks_path
    expect(page).to have_button("Remove bookmark")
    expect(page).to have_content("Strong Medicine speaks")
  end

  it "cites items in bookmarks" do
    visit solr_document_path('2007020969')
    click_on 'Bookmark'
    click_on 'Bookmarks'
    click_on 'Cite'
    expect(page).to have_content 'Strong Medicine speaks'
  end

  it "cites all items in current bookmarks" do
    visit solr_document_path('2009373513') # Ci an zhou bian
    click_on 'Bookmark'

    visit solr_document_path('2007020969') # Strong Medicine speaks
    click_on 'Bookmark'

    visit "/bookmarks?per_page=1"
    expect(page).to have_content 'Strong Medicine speaks'
    expect(page).to have_no_content 'Ci an zhou bian'

    click_on 'Cite'
    expect(page).to have_content 'Strong Medicine speaks'
    expect(page).to have_content 'Ci an zhou bian'
  end
end
