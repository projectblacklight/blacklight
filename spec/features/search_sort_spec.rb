# frozen_string_literal: true
require 'spec_helper'

describe "Search Sort" do
  it "should sort on facet results with no search terms" do
    visit root_path
    within "#facet-language_facet" do
      click_link 'English'
    end
    expect(page).to have_content 'Sort by relevance'
    click_link 'title'
    expect(page).to have_content 'Sort by title'
  end

  it "should sort on search" do
    visit root_path
    fill_in "q", with: 'bod'
    click_button 'search'
    expect(page).to have_content 'Sort by relevance'
    click_link 'title'
    expect(page).to have_content 'Sort by title'
  end
end
