# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module BookmarkSpecHelper
  def valid_bookmark_attributes
    {
      :id => 1,
      :user_id => 1,
      :document_id => 'u001'
    }
  end
end

describe Bookmark do
  include BookmarkSpecHelper
  before(:each) do
    @bookmark = Bookmark.new
  end
  
  it "should be valid" do
    @bookmark.assign_attributes valid_bookmark_attributes, :without_protection => true
    @bookmark.should be_valid
  end
   
  it "should require user_id" do
    @bookmark.should have(1).error_on(:user_id)
  end

  it "should belong to user" do
    Bookmark.reflect_on_association(:user).should_not be_nil
  end

  it "should be valid after saving" do
    @bookmark.assign_attributes valid_bookmark_attributes, :without_protection => true
    @bookmark.save
    @bookmark.should be_valid
  end
end
