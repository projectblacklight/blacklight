# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Bookmark do
  before(:each) do
    @bookmark = Bookmark.new
  end
  
  it "should be valid" do
    @bookmark.id = 1
    @bookmark.user_id = 1
    @bookmark.document_id = 'u001'
    @bookmark.should be_valid
  end
   
  it "should require user_id" do
    @bookmark.should have(1).error_on(:user_id)
  end

  it "should belong to user" do
    Bookmark.reflect_on_association(:user).should_not be_nil
  end

  it "should be valid after saving" do
    @bookmark.id = 1
    @bookmark.user_id = 1
    @bookmark.document_id = 'u001'
    @bookmark.save
    @bookmark.should be_valid
  end
end
