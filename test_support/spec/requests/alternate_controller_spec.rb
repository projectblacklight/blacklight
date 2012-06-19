# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "controllers that are not catalog controller" do

  it "should have the correct search form" do
    visit alternate_index_path
    page.should have_selector("form[action='#{alternate_index_path}']")
    fill_in "q", :with=>"history"
    click_button 'search'
    page.should have_link("startOverLink", :href=>alternate_index_path)
    page.should have_selector("form.per_page[action='#{alternate_index_path}']")
    page.should have_selector("form#sort_form[action='#{alternate_index_path}']")
  end
end
