require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe HomeController do

  before(:each) do
    @facet = {:format_facet=>'Book'}
  end

  describe 'index action' do

    # ROUTES and MAPPING
    it "should be the default route" do
      route_for(:controller => 'home', :action => 'index').should == "/"      
    end
    it "should map default route to {:controller => 'home'}" do
      params_from(:get, '/').should == {:controller => 'home', :action => 'index'}
    end
    
    # for EACH ACTION: Rendering, Status Code, Etc.
    # NOTE: status code is always 200 in isolation mode ...
    it "should render index.html.erb" do
      get :index
      response.should render_template(:index)
    end    
    # NOTE: status code is always 200 in isolation mode ...
    it "HTTP status code for GET should be 200" do
      get :index
      response.should be_success
    end
    
    # when a facet vaue is selected ...
    describe "has a facet param (f), the action" do
      it "should be a redirect to catalog controller, with the f param set" do
        get :index, :f => @facet
        response.should redirect_to(:controller=>'catalog', :action => 'index', :f => @facet)
      end
    end
        
  end # describe index action

end
