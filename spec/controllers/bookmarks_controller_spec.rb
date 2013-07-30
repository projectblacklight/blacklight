# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BookmarksController do
  include Devise::TestHelpers
  
  # jquery 1.9 ajax does error callback if 200 returns empty body. so use 204 instead. 
  describe "update" do
    it "has a 204 status code when creating a new one" do
      xhr :put, :update, :id => '2007020969', :format => :js
      response.should be_success
      response.code.should == "204"
    end
    
    it "has a 500 status code when fails is success" do
      @controller.stub_chain(:current_or_guest_user, :existing_bookmark_for).and_return(false)
      @controller.stub_chain(:current_or_guest_user, :persisted?).and_return(true)
      @controller.stub_chain(:current_or_guest_user, :bookmarks, :create).and_return(false)  
      xhr :put, :update, :id => 'iamabooboo', :format => :js
      response.code.should == "500"
    end
  end
  
  describe "delete" do
    it "has a 204 status code when delete is success" do
      xhr :delete, :destroy, :id => '2007020969', :format => :js
      response.should be_success
      response.code.should == "204"
    end

   it "has a 500 status code when delete is not success" do
      bm = double(Bookmark)
      @controller.stub_chain(:current_or_guest_user, :existing_bookmark_for).and_return(bm)
      @controller.stub_chain(:current_or_guest_user, :bookmarks, :delete).and_return(false)
     
      xhr :delete, :destroy, :id => 'pleasekillme', :format => :js
     #
      response.code.should == "500"
    end
  end
  
end