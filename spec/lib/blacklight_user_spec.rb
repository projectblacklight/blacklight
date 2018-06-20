# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Blacklight::User" do

  subject { User.create! :email => 'xyz@example.com', :password => 'xyz12345' }
  
  around(:each) do |example|
    Deprecation.silence(Blacklight::User) { example.run }
  end

  def mock_bookmark document_id
    Bookmark.new :document_id => document_id
  end

  it "should know if it doesn't have bookmarks" do
    expect(subject).to_not have_bookmarks
  end

  it "should know if it has bookmarkss" do
    subject.bookmarks << mock_bookmark(1)
    subject.bookmarks << mock_bookmark(2)

    expect(subject).to have_bookmarks
  end

  it "should know if it has a bookmarked document" do
    subject.bookmarks << mock_bookmark(1)
    expect(subject.document_is_bookmarked?(1)).to eq true
  end

  it "should be able to create bookmarks in batches" do
    @md1 = { :document_id => 1 }
    @md2 = { :document_id => 2 }
    @md3 = { :document_id => 3 }

    subject.documents_to_bookmark= [@md1,@md2,@md3]
    expect(subject.bookmarks.size).to eq(3)
    expect(subject.bookmarked_document_ids).to include("1","2","3")

  end

  it "should not recreate bookmarks for documents already bookmarked" do
    subject.bookmarks << mock_bookmark(1)

    @md1 = { :document_id => 1 }
    expect(subject.bookmarks).not_to receive(:create).with(@md1)

    subject.bookmarks.push(mock_bookmark(1))
    subject.documents_to_bookmark=[@md1]
  end

  it "should know if it doesn't have a search" do
    expect(subject.has_searches?).to eq(false)
  end

  it "should know if it has a search" do
    subject.searches << Search.new
    expect(subject.has_searches?).to eq(true)
  end

end    
