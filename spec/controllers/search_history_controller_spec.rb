# frozen_string_literal: true
require 'spec_helper'

describe SearchHistoryController do
  routes { Blacklight::Engine.routes }

  describe "index" do
    before(:all) do
      @one = Search.create
      @two = Search.create
      @three = Search.create
    end

    it "onlies fetch searches with ids in the session" do
      session[:history] = [@one.id, @three.id]
      get :index
      @searches = assigns(:searches)
      expect(@searches).to have(2).searches
      expect(@searches).to include(@one)
      expect(@searches).to include(@three)
      expect(@searches).to_not include(@two)
    end
    
    it "tolerates bad ids in session" do
      session[:history] = [@one.id, @three.id, "NOT_IN_DB"]
      get :index
      @searches = assigns(:searches)
      expect(@searches).to have(2).searches
      expect(@searches).to include(@one)
      expect(@searches).to include(@three)      
    end
    
    it "does not fetch any searches if there is no history" do
      session[:history] = []
      get :index
      @searches = assigns(:searches)
      expect(@searches).to be_empty
    end
  end
end
