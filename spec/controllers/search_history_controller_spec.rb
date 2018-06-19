# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchHistoryController do
  include Devise::TestHelpers

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
      expect(@searches.length).to eq(2)
      expect(@searches).to include(@one)
      expect(@searches).to include(@three)
      expect(@searches).not_to include(@two)
    end
    
    it "should tolerate bad ids in session" do
      session[:history] = [@one.id, @three.id, "NOT_IN_DB"]
      get :index
      @searches = assigns(:searches)
      expect(@searches.length).to eq(2)
      expect(@searches).to include(@one)
      expect(@searches).to include(@three)      
    end
    
    it "should not fetch any searches if there is no history" do
      session[:history] = []
      get :index
      @searches = assigns(:searches)
      expect(@searches.length).to eq(0)
    end
  end



end
