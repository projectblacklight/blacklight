# frozen_string_literal: true

RSpec.describe "Record View" do
  it "displays a normal record" do
    visit solr_document_path('2007020969')
    expect(page).to have_text "Title:"
    expect(page).to have_text "Strong Medicine speaks"
    expect(page).to have_text "Subtitle:"
    expect(page).to have_text "a Native American elder has her say : an oral history"
    expect(page).to have_text "Author:"
    expect(page).to have_text "Hearth, Amy Hill, 1958-"
    expect(page).to have_text "Format:"
    expect(page).to have_text "Book"
    expect(page).to have_text "Call number:"
    expect(page).to have_text "E99.D2 H437 2008"
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    expect(page).to have_css("link[rel=alternate]")
    Capybara.ignore_hidden_elements = tmp_value
  end

  it "does not display blank titles" do
    visit solr_document_path('2008305903')
    expect(page).to have_no_text "More Information:"
  end

  it "does not display vernacular records" do
    visit solr_document_path('2009373513')
    expect(page).to have_text "次按驟變"
    expect(page).to have_text "林行止"
    expect(page).to have_text "臺北縣板橋市"
  end
end
