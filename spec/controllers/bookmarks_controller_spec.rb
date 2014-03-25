require 'spec_helper'

describe BookmarksController do
  include Devise::TestHelpers

  describe "index" do
    render_views

    before(:all) do
      # creating a user without persisting it seems to work
      @user_with_3 = User.new
      # 3 ids from the sample data set
      @user_with_3.bookmarks.new(:document_id => '43037890')
      @user_with_3.bookmarks.new(:document_id => '53029833')
      @user_with_3.bookmarks.new(:document_id => '77826928')

    end

    context ".endnote format" do
      it "returns records in endnote format" do
        @controller.stub(:current_or_guest_user).and_return(@user_with_3)

        get :index, :format => :endnote

        expect(response.code).to eq "200"

        # For some reason having trouble getting actual doc.export_as(:endnote)
        # to compare it, so we just make sure it seems mostly endnote-like, 3
        # records seperated by blank lines. 
        expect(response.body).to match /\A(%. .*\n)+\n(%. .*\n)+\n(%. .*\n)+\Z/
      end
    end
  end

  describe "export" do
    render_views

    before(:all) do
      # We don't persist the user, but we're gonna have to mock
      # User.find to find it. 
      @user_with_3 = User.new
      # 3 ids from the sample data set
      @user_with_3.bookmarks.new(:document_id => '43037890')
      @user_with_3.bookmarks.new(:document_id => '53029833')
      @user_with_3.bookmarks.new(:document_id => '77826928')
    end

    context ".refworks_marc_txt format" do
      it "returns records in refworks_marc_txt format from encrypted_user_id" do
        user_id = 9999999999
        encrypted_user_id = @controller.send(:encrypt_user_id, user_id)
        
        User.should_receive(:find).with(user_id).and_return(@user_with_3)

        get :export, :format => :refworks_marc_txt, :encrypted_user_id => encrypted_user_id

        expect(response.code).to eq "200"
        # For some reason having trouble getting actual doc.export_as(:refworks_marc_txt)
        # to compare it, so we just make sure it seems to match the format for 3
        # such records seperated by blank lines. 
        rmt_regex = 'LEADER .+\n(\d\d\d .. .+\n)+'
        expect(response.body).to match /\A#{rmt_regex}\n#{rmt_regex}\n#{rmt_regex}\Z/
      end
    end
  end
  
  # jquery 1.9 ajax does error callback if 200 returns empty body. so use 204 instead. 
  describe "update" do
    it "has a 204 status code when creating a new one" do
      xhr :put, :update, :id => '2007020969', :format => :js
      expect(response).to be_success
      expect(response.code).to eq "204"
    end
    
    it "has a 500 status code when fails is success" do
      @controller.stub_chain(:current_or_guest_user, :existing_bookmark_for).and_return(false)
      @controller.stub_chain(:current_or_guest_user, :persisted?).and_return(true)
      @controller.stub_chain(:current_or_guest_user, :bookmarks, :create).and_return(false)  
      xhr :put, :update, :id => 'iamabooboo', :format => :js
      expect(response.code).to eq "500"
    end
  end
  
  describe "delete" do
    it "has a 204 status code when delete is success" do
      xhr :delete, :destroy, :id => '2007020969', :format => :js
      expect(response).to be_success
      expect(response.code).to eq "204"
    end

   it "has a 500 status code when delete is not success" do
      bm = double(Bookmark)
      @controller.stub_chain(:current_or_guest_user, :existing_bookmark_for).and_return(bm)
      @controller.stub_chain(:current_or_guest_user, :bookmarks, :delete).and_return(false)
     
      xhr :delete, :destroy, :id => 'pleasekillme', :format => :js

      expect(response.code).to eq "500"
    end
  end
  
end