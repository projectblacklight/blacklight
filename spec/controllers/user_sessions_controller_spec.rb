require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe UserSessionsController do
  before(:each) do
    # you must activate authlogic in order to test any authentication methods
    activate_authlogic
    @user = User.create!(:password => "password", :password_confirmation => "password", :login => "foo", :email => "foo@bar.com")
  end
  describe "create" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      activate_authlogic
      request.env["HTTP_REFERER"] = "/"
    end

    it "should redirect user to root url" do
      post :create, :user_session => { :password => "password", :login => "foo" }
      response.redirected_to.should ==root_path
    end

    it "should redirect user to referer url in params" do
      post :create, :user_session => { :password => "password", :login => "foo"}, :referer => '/catalog/asdf' 
      response.redirected_to.should =='/catalog/asdf'
    end

    it "should redirect user to referer url in HTTP_REFERER" do
      request.env["HTTP_REFERER"] = '/catalog/1234'
      post :create, :user_session => { :password => "password", :login => "foo" }
      response.redirected_to.should =='/catalog/1234'
    end

    it "should prefer params referer to request referer" do
      request.env["HTTP_REFERER"] = '/catalog/1234'
      post :create, :user_session => { :password => "password", :login => "foo"}, :referer => '/catalog/asdf'
      response.redirected_to.should =='/catalog/asdf'
    end

    it "should filter referer urls" do
      post :create, :user_session => { :password => "password", :login => "foo" }, :referer => 'http://other.server.example.org/catalog/asdf'
      response.redirected_to.should == root_path
      
      request.env["HTTP_HOST"] = 'example.org'
      post :create, :user_session => { :password => "password", :login => "foo" }, :referer => 'http://example.org/catalog/asdf'
      response.redirected_to.should == '/catalog/asdf' 
    end
  end

  describe "destroy" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      @user_session = UserSession.create!(:password => "password", :login => "foo")
      activate_authlogic
      request.env["HTTP_REFERER"] = "/"
    end

    it "should redirect user to root url" do
      delete :destroy
      response.redirected_to.should == root_path
    end

    it "should redirect user to referer url in HTTP_REFERER" do
      request.env["HTTP_REFERER"] = '/catalog/1234'
      delete :destroy
      response.redirected_to.should =='/catalog/1234'
    end
  end

end
