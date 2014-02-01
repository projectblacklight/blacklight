require 'spec_helper'

describe "Blacklight::User" do

  subject { User.create! :email => 'xyz@example.com', :password => 'xyz12345' }

  def mock_bookmark document_id
    Bookmark.new :document_id => document_id
  end

  it "should know if it has a bookmarked document" do
    subject.bookmarks << mock_bookmark(1)
    expect(subject.document_is_bookmarked?(1)).to be_true
  end

end    
