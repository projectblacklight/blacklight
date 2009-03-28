require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

module UserSpecHelper
  def valid_user_attributes
    {
      :id => 1,
      :login => 'test_user_one',
      :email => 'user1@test.com',
      :last_login=> '2008-04-09 14:11:12',
      :password => 'password1'
    }
  end
  
  def user_attributes_with_same_login 
  {
    :id => 2,
    :login => 'test_user_one',
    :email => 'user2@test.com',
    :last_login=> '2008-05-09 14:11:12',
    :password => 'password2'
  }
  end
  
  def user_attributes_with_same_email
    {
      :id => 3,
      :login => 'test_user_three',
      :email => 'user1@test.com',
      :last_login=> '2008-04-10 14:11:12',
      :password => 'password3'
    }
  end

  def valid_bookmark_attributes
    {
      :id => 1,
      :user_id => 1,
      :document_id => 'u001'      
    }
  end
  
  def get_bookmark
    @bookmark = Bookmark.new
    @bookmark.attributes = valid_bookmark_attributes
    @bookmark
  end
          
end

describe User do
  include UserSpecHelper
  before(:each) do
    @user = User.new
    @user.attributes = valid_user_attributes
  end
    
  it "should be valid" do
    @user.should be_valid
  end
  
  it "should require email" do
    @user = User.new
    @user.should have(1).error_on(:email)
  end

  it "should have unique login" do
    lambda do
      User.create(valid_user_attributes)
      User.create(user_attributes_with_same_email)
      end.should change(User, :count).by(1)
  end

  it "should require login" do    
    @user = User.new
    @user.should have(1).error_on(:login)
  end

  it "should have unique login" do
    lambda do
      User.create(valid_user_attributes)
      User.create(user_attributes_with_same_login)
      end.should change(User, :count).by(1)
  end

  it "should require password" do
    @user = User.new
    @user.should have(1).error_on(:password)
  end

  it "should be able to have many bookmarks" do
    @user.bookmarks.push(get_bookmark)
    @user.bookmarks.push(get_bookmark)
    @user.save
    @user.should be_valid
  end

  it "should know if it has bookmarks" do
    @user.bookmarks.push(get_bookmark)
    @user.save
    @user.should be_has_bookmarks
  end

  it "should know if it is real" do
    @user.save
    @user.should be_is_real
  end

  it "should know if it is not real" do
    @user.should_not be_is_real
  end
  
  it "should know if it has a document bookmarked" do
    @user.bookmarks.push(get_bookmark)
    @user.should be_document_is_bookmarked('u001')  
  end

  it "should be valid after saving" do
    @user.save
    @user.should be_valid
  end
end