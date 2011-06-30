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
    
    it "should tolerate bad ids in session" do
      session[:history] = [@one.id, @three.id, "NOT_IN_DB"]
      get :index
      @searches = assigns(:searches)
      @searches.length.should == 2
      @searches.should include(@one)
      @searches.should include(@three)      
    end
    
    it "should not fetch any searches if there is no history" do
      session[:history] = []
      get :index
      @searches = assigns(:searches)
      @searches.length.should == 0
    end
  end



end
