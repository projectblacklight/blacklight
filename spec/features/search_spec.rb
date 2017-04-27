# frozen_string_literal: true

RSpec.describe "Search Page" do
  it "shows welcome" do
    visit root_path
    expect(page).to have_selector("input#q")
    within ("select#search_field") do
      expect(page).to have_selector('option', text: 'All Fields')
      expect(page).to have_selector('option', text: 'Title')
      expect(page).to have_selector('option', text: 'Author')
      expect(page).to have_selector('option', text: 'Subject')
    end
    expect(page).to have_selector("button[type='submit'] .submit-search-text")
    expect(page).to_not have_link "Start Over"
   
    expect(page).to have_content "Welcome!"
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_selector("link[rel=stylesheet]")
    Capybara.ignore_hidden_elements = tmp_value
  end

  it "does searches across all fields" do
    visit root_path
    fill_in "q", with: 'history'
    select 'All Fields', from: 'search_field'
    click_button 'search'
   
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_selector("link[rel=alternate][type='application/rss+xml']")
    expect(page).to have_selector("link[rel=alternate][type='application/atom+xml']")
    expect(page).to have_selector("link[rel=alternate][type='application/json']")

    # opensearch
    expect(page).to have_selector("meta[name=totalResults]")
    expect(page).to have_selector("meta[name=startIndex]")
    expect(page).to have_selector("meta[name=itemsPerPage]")
    Capybara.ignore_hidden_elements = tmp_value

    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end

    within ("select#search_field") do
      expect(page).to have_selector("option[selected]", text: "All Fields")
    end

    within ("#sortAndPerPage") do
      expect(page).to have_content "Sort by"
      expect(page).to have_content "1 - 9 of 9"
      within '#sort-dropdown' do
        expect(page).to have_link('relevance')
        expect(page).to have_link('year')
        expect(page).to have_link('author')
        expect(page).to have_link('title')
      end
    end
    within "#documents" do
      expect(page).to have_selector(".document", count: 9)
    end
  end

  it "does searches constrained to a single field" do
    visit root_path
    fill_in "q", with: 'inmul'
    select 'Title', from: 'search_field'
    click_button 'search'

    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "Title"
      expect(page).to have_content "inmul"
    end
    within ("select#search_field") do
      expect(page).to have_selector("option[selected]", text: "Title")
    end
    within(".index_title") do
      expect(page).to have_content "1."
    end
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 entry found"
    end
  end

  it "shows vernacular (Linked 880) and call number" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within "#documents" do
      expect(page).to have_content "次按驟變"
      expect(page).to have_content "DK861.K3 V5"
    end
  end

  it "allows you to clear the search" do
    visit root_path
    fill_in "q", with: 'history'
    click_button 'search'
    within "#appliedParams" do
      expect(page).to have_content "You searched for:"
      expect(page).to have_content "history"
    end

    expect(page).to have_selector "#q[value='history']"

    click_link "Start Over"

    expect(page).to have_content "Welcome!"
    expect(page).to_not have_selector "#q[value='history']"
  end

  it "handles searches with invalid facet parameters" do
    visit root_path f: { missing_s: [1]}
    expect(page).to have_content "No results found for your search"
  end
end

