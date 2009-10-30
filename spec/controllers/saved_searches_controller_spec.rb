require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SavedSearchesController do
  before(:each) do
    # you must activate authlogic in order to test any authentication methods
    activate_authlogic
    @user = User.create!(:password => "password", :password_confirmation => "password", :login => "foo", :email => "foo@bar.com")
    @user_session = UserSession.create!(:password => "password", :login => "foo")
    request.env["HTTP_REFERER"] = "/"
  end
  describe "destroy" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      activate_authlogic
      @user.searches.create!
      @user.searches.size.should == 1
      @search_id = @user.search_ids.first
    end
    it "should NULL out the user_id for the given id" do
      delete(:destroy, :id => @search_id)
      @user.searches.size.should == 0
      Search.find(@search_id).should_not be_nil
    end
  end

end
