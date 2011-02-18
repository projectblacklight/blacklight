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
      response.redirect_url.should == root_url
    end

    it "should redirect user to referer url in params" do
      post :create, :user_session => { :password => "password", :login => "foo"}, :referer => '/catalog/asdf' 
      response.redirect_url.should match '/catalog/asdf'
    end

    it "should redirect user to referer url in HTTP_REFERER" do
      request.env["HTTP_REFERER"] = '/catalog/1234'
      post :create, :user_session => { :password => "password", :login => "foo" }
      response.redirect_url.should match '/catalog/1234'
    end        

    it "should prefer params referer to request referer" do
      request.env["HTTP_REFERER"] = '/catalog/1234'
      post :create, :user_session => { :password => "password", :login => "foo"}, :referer => '/catalog/asdf'
      response.redirect_url.should match '/catalog/asdf'
    end

    it "should filter referer urls" do
      post :create, :user_session => { :password => "password", :login => "foo" }, :referer => 'http://other.server.example.org/catalog/asdf'
      response.redirect_url.should == root_url
      
      request.host = 'example.org'
      post :create, :user_session => { :password => "password", :login => "foo" }, :referer => 'http://example.org/catalog/asdf'
      response.redirect_url.should match '/catalog/asdf' 
    end
    
    it "should redirect even if port is in hostname" do
      request.host = "example.org" 
      request.port = "3000"
      request.env['HTTP_HOST'] = "example.org:3000"

      request.env["HTTP_REFERER"] = "http://example.org:3000/catalog/asdf?foo=bar"
      post :create, :user_session => { :password => "password", :login => "foo" }
      response.redirect_url.should == root_url + 'catalog/asdf?foo=bar' 
    end
    
    it "should not redirect to a third party host" do
      request.host = "example.org"
      request.env["HTTP_REFERER"] = "http://somewhere.else/catalog/foo"
      post :create, :user_session => { :password => "password", :login => "foo" }
      response.redirect_url.should == root_url
    end
    
    it "should not accept a relative path URL" do
      post :create, :user_session => { :password => "password", :login => "foo", :referer => "foobar" }
      response.redirect_url.should == root_url
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
      response.redirect_url.should == root_url
    end

    it "should redirect user to referer url in HTTP_REFERER" do
      request.env["HTTP_REFERER"] = '/catalog/1234'
      delete :destroy
      response.redirect_url.should == root_url + 'catalog/1234'
    end
  end

end
