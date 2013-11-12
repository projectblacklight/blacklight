# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "Record View" do
  it "should display a normal record" do
    visit catalog_path('2007020969')
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
    expect(page).to have_selector("link[rel=alternate]")
    
  end

  it "should not display blank titles" do
    visit catalog_path('2008305903')
    expect(page).not_to have_content "More Information:" 
  end

  it "should not display vernacular records" do
    visit catalog_path('2009373513')
    expect(page).to have_content "次按驟變" 
    expect(page).to have_content "林行止" 
    expect(page).to have_content "臺北縣板橋市" 
  end
  it "should not display 404" do
    visit catalog_path('this_id_does_not_exist')
    page.driver.status_code.should == 404
    expect(page).to have_content "Sorry, you have requested a record that doesn't exist." 
  end
end
