require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Blacklight::User" do
  class MockUser
    include Blacklight::User::InstanceMethods
    attr_accessor :searches
    attr_accessor :bookmarks
  end

  class MockBookmark
    attr_accessor :document_id

    def initialize document_id
      self.document_id = document_id
    end
  end

  before(:each) do
    @user = MockUser.new
    @user.searches = []
    @user.bookmarks = []
  end

  def mock_bookmark doc_id
    MockBookmark.new doc_id
  end

  it "should know if it doesn't have bookmarks" do
    @user.has_bookmarks?.should == false
  end

  it "should know if it has bookmarkss" do
    @user.bookmarks.push(mock_bookmark(1))
    @user.bookmarks.push(mock_bookmark(2))
    @user.has_bookmarks?.should == true
  end

  it "should know if it has a bookmarked document" do
    @user.bookmarks.push(mock_bookmark(1))
    @user.should be_document_is_bookmarked(1)
  end

  it "should return a bookmark it a document is bookmarked" do
    @user.bookmarks.push(mock_bookmark(1))
    @user.existing_bookmark_for(1).should be_a_kind_of(MockBookmark)
  end

  it "should be able to create bookmarks in batches" do
    @md1 = { :document_id => 1 }
    @md2 = { :document_id => 2 }
    @md3 = { :document_id => 3 }
    @user.bookmarks.should_receive(:create).with(@md1)
    @user.bookmarks.should_receive(:create).with(@md2)
    @user.bookmarks.should_receive(:create).with(@md3)

    @user.documents_to_bookmark= [@md1,@md2,@md3]
  end

  it "should not recreate bookmarks for documents already bookmarked" do
    @md1 = { :document_id => 1 }
    @user.bookmarks.should_not_receive(:create).with(@md1)

    @user.bookmarks.push(mock_bookmark(1))
    @user.documents_to_bookmark=[@md1]
  end

  it "should know if it doesn't have a search" do
    @user.has_searches?.should == false
  end

  it "should know if it has a search" do
    @user.searches.push(1)
    @user.has_searches?.should == true
  end

end    
