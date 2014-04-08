require 'spec_helper'

describe SavedSearchesController do

  before(:all) do
    @one = Search.create
    @two = Search.create
    @three = Search.create
  end

  before(:each) do
    @user = User.create! :email => 'test@example.com', :password => 'abcd12345', :password_confirmation => 'abcd12345'
    sign_in @user  
  end

  describe "save" do
    it "should let you save a search" do

      request.env["HTTP_REFERER"] = "where_i_came_from"
      session[:history] = [@one.id]
      post :save, :id => @one.id
      expect(response).to redirect_to "where_i_came_from"
    end

    it "should not let you save a search that isn't in your search history" do
      session[:history] = [@one.id]
      expect {
        post :save, :id => @two.id
      }.to raise_exception
    end

  end



end
