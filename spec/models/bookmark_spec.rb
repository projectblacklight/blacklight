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
    expect(@bookmark).to be_valid
  end

  it "should require user_id" do
    expect(@bookmark).not_to be_valid
    expect(@bookmark.errors[:user_id].length).to eq 1
  end

  it "should belong to user" do
    expect(Bookmark.reflect_on_association(:user)).not_to be_nil
  end

  it "should be valid after saving" do
    @bookmark.id = 1
    @bookmark.user_id = 1
    @bookmark.document_id = 'u001'
    @bookmark.save
    expect(@bookmark).to be_valid
  end
end
