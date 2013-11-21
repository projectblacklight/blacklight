require 'spec_helper'

describe "Librarian view" do
  it "should show marc fields" do
    visit catalog_path('2009373513')
    click_link "Librarian View"
    expect(page).to have_content "Librarian View"
    expect(page).to have_content "LEADER 01213nam a22003614a 4500"
    expect(page).to have_content "100"
    expect(page).to have_content "Lin, Xingzhi."
    expect(page).to have_content "6|"
  end
end
