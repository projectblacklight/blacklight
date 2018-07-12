# frozen_string_literal: true

RSpec.describe "Did You Mean" do
  before { visit root_path }

  describe "searching all fields" do
    it "has suggestions" do
      fill_in "q", with: 'politica'
      click_button 'search'

      expect(page).to have_content("Did you mean")
      click_link 'policy'
      within ("#sortAndPerPage") do
        expect(page).to have_content "1 - 2 of 2"
      end
    end
  end

  describe "for a title search" do
    before { select 'Title', from: 'search_field' }
    it "has suggestions" do
      # yehudiyam is one letter away from a title word
      fill_in "q", with: 'yehudiyam'
      click_button 'search'

      expect(page).to have_content("Did you mean")
      click_link 'yehudiyim'
      within ("#sortAndPerPage") do
        expect(page).to have_content "1 entry found"
      end
      within ("select#search_field") do
        expect(page).to have_selector("option[selected]", text: "Title")
      end
    end
  end

  describe "for an author search" do
    before { select 'Author', from: 'search_field' }
    it "has suggestions" do
      # shirma is one letter away from an author word
      fill_in "q", with: 'shirma'
      click_button 'search'

      expect(page).to have_content("Did you mean")
      click_link 'sharma'
      within ("#sortAndPerPage") do
        expect(page).to have_content "1 entry found"
      end
      within ("select#search_field") do
        expect(page).to have_selector("option[selected]", text: "Author")
      end
    end
  end

  describe "for an subject search" do
    before { select 'Subject', from: 'search_field' }
    it "has suggestions" do
      # wome is one letter away from an author word
      fill_in "q", with: 'wome'
      click_button 'search'

      expect(page).to have_content("Did you mean")
      click_link 'women'
      within ("#sortAndPerPage") do
        expect(page).to have_content "1 - 3 of 3"
      end
      within ("select#search_field") do
        expect(page).to have_selector("option[selected]", text: "Subject")
      end
    end
  end

  describe "a multiword query" do
    it "does not have suggestions if there are no matches" do
      fill_in "q", with: 'ooofda ooofda'
      click_button 'search'

      expect(page).to_not have_content("Did you mean")
    end

    it "has separate suggestions" do
      fill_in "q", with: 'politica boo'
      click_button 'search'

      within(".suggest") do
        expect(page).to have_content("Did you mean")
        expect(page).to have_link('policy')
        expect(page).to have_link('bon')
        expect(page).not_to have_link('policy bon')
      end

      click_link 'bon'
      within ("#sortAndPerPage") do
        expect(page).to have_content "1 entry found"
      end
    end

    it "ignores repeated terms" do
      fill_in "q", with: 'boo boo'
      click_button 'search'

      within(".suggest") do
        expect(page).to have_content("Did you mean")
        expect(page).to have_link('bon', count: 1)
        expect(page).not_to have_link('bon bon')
      end
    end
  end

  it "shows suggestions if there aren't many hits" do
    fill_in "q", with: 'ayaz'
    click_button 'search'

    expect(page).to have_content("Did you mean")
    click_link 'bya'
    within ("#sortAndPerPage") do
      expect(page).to have_content "1 - 3 of 3"
    end
  end


  it "shows suggestions if at the threshold number" do
    # polit gives 5 results in 30 record demo index - 5 is default cutoff
    fill_in "q", with: 'polit'
    click_button 'search'
    expect(page).to have_content("Did you mean")
  end

end
