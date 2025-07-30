# frozen_string_literal: true

RSpec.describe "Search Page" do
  it 'declares the page language in the html lang attribute' do
    visit root_path
    expect(page).to have_css('html[lang=en]')
  end

  it "shows welcome" do
    visit root_path
    expect(page).to have_field("search for")
    within ("select#search_field") do
      expect(page).to have_css('option', text: 'All Fields')
      expect(page).to have_css('option', text: 'Title')
      expect(page).to have_css('option', text: 'Author')
      expect(page).to have_css('option', text: 'Subject')
    end
    expect(page).to have_css("button[type='submit'] .submit-search-text")
    expect(page).to have_no_link "Start Over"

    expect(page).to have_content "Welcome!"
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_css("link[rel=stylesheet]")
    Capybara.ignore_hidden_elements = tmp_value
  end

  it "does searches across all fields" do
    visit root_path
    fill_in "q", with: 'history'
    select 'All Fields', from: 'search_field'
    click_on 'search'

    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_css("link[rel=alternate][type='application/rss+xml']")
    expect(page).to have_css("link[rel=alternate][type='application/atom+xml']")
    expect(page).to have_css("link[rel=alternate][type='application/json']")

    # opensearch
    expect(page).to have_css("meta[name=totalResults]")
    expect(page).to have_css("meta[name=startIndex]")
    expect(page).to have_css("meta[name=itemsPerPage]")
    Capybara.ignore_hidden_elements = tmp_value

    within "#appliedParams" do
      expect(page).to have_css('h2', text: 'Your selections:')
      expect(page).to have_content "history"
    end

    within ("select#search_field") do
      expect(page).to have_css("option[selected]", text: "All Fields")
    end

    within ("#sortAndPerPage") do
      expect(page).to have_content "Sort by"
      expect(page).to have_content "1 - 10 of 11"
      within '#sort-dropdown' do
        expect(page).to have_link('relevance')
        expect(page).to have_link('year')
        expect(page).to have_link('author')
        expect(page).to have_link('title')
      end
    end
    within "#documents" do
      expect(page).to have_css(".document", count: 10)
    end
  end

  it "does searches constrained to a single field" do
    visit root_path
    fill_in "q", with: 'inmul'
    select 'Title', from: 'search_field'
    click_on 'search'

    within "#appliedParams" do
      expect(page).to have_css('h2', text: 'Your selections:')
      expect(page).to have_content "Title"
      expect(page).to have_content "inmul"
    end
    within ("select#search_field") do
      expect(page).to have_css("option[selected]", text: "Title")
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
    click_on 'search'
    within "#documents" do
      expect(page).to have_content "次按驟變"
      expect(page).to have_content "DK861.K3 V5"
    end
  end

  it "allows you to clear the search" do
    visit root_path
    fill_in "q", with: 'history'
    click_on 'search'
    within "#appliedParams" do
      expect(page).to have_css('h2', text: 'Your selections:')
      expect(page).to have_content "history"
    end

    expect(page).to have_css "#q[value='history']"

    click_on "Start Over"

    expect(page).to have_content "Welcome!"
    expect(page).to have_no_css "#q[value='history']"
  end
end
