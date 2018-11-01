# frozen_string_literal: true

RSpec.describe "Record View" do
  it "displays a normal record" do
    visit solr_document_path('2007020969')
    expect(page).to have_content "Title:"
    expect(page).to have_content "Strong Medicine speaks"
    expect(page).to have_content "Subtitle:"
    expect(page).to have_content "a Native American elder has her say : an oral history"
    expect(page).to have_content "Author:"
    expect(page).to have_content "Hearth, Amy Hill, 1958-"
    expect(page).to have_content "Format:"
    expect(page).to have_content "Book"
    expect(page).to have_content "Call number:"
    expect(page).to have_content "E99.D2 H437 2008"
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_selector("link[rel=alternate]")
    Capybara.ignore_hidden_elements = tmp_value
  end

  it "does not display blank titles" do
    visit solr_document_path('2008305903')
    expect(page).not_to have_content "More Information:"
  end

  it "does not display vernacular records" do
    visit solr_document_path('2009373513')
    expect(page).to have_content "次按驟變"
    expect(page).to have_content "林行止"
    expect(page).to have_content "臺北縣板橋市"
  end
end
