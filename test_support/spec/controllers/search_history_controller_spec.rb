# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchHistoryController do
  describe "index" do
    before(:all) do
      @one = Search.create
      @two = Search.create
      @three = Search.create
    end

    it "should only fetch searches with ids in the session" do
      session[:history] = [@one.id, @three.id]
      get :index
      @searches = assigns(:searches)
      @searches.length.should == 2
      @searches.should include(@one)
      @searches.should include(@three)
      @searches.should_not include(@two)
    end
    
    it "should not fetch any searches if there is no history" do
      session[:history] = []
      get :index
      @searches = assigns(:searches)
      @searches.length.should == 0
    end
  end

  describe "destroy" do
    it "should delete the search by id from the search history not by array index" do
      session[:history] = [1,2,2]
      request.env["HTTP_REFERER"] = "/search_history"
      get :destroy, :id=>1
      session[:history].length.should == 2
    end
    it "should return a flash error if an id that is not in the users search history is deleted" do
      session[:history] = [1,2,3]
      request.env["HTTP_REFERER"] = "/search_history"
      get :destroy, :id=>4
      request.flash[:error].should_not == ""
    end
    
  end

end
