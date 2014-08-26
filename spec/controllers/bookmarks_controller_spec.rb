require 'spec_helper'

describe BookmarksController do
  # jquery 1.9 ajax does error callback if 200 returns empty body. so use 204 instead. 
  describe "update" do
    it "has a 200 status code when creating a new one" do
      xhr :put, :update, :id => '2007020969', :format => :js
      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 1
    end
    
    it "has a 500 status code when create is not success" do
      allow(@controller).to receive_message_chain(:current_or_guest_user, :existing_bookmark_for).and_return(false)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :persisted?).and_return(true)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :where, :exists?).and_return(false)  
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :create).and_return(false)  
      xhr :put, :update, :id => 'iamabooboo', :format => :js
      expect(response.code).to eq "500"
    end
  end
  
  describe "delete" do
    before do
      @controller.send(:current_or_guest_user).save
      @controller.send(:current_or_guest_user).bookmarks.create! document_id: '2007020969', document_type: "SolrDocument"
    end
    
    it "has a 200 status code when delete is success" do
      xhr :delete, :destroy, :id => '2007020969', :format => :js
      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 0
    end

   it "has a 500 status code when delete is not success" do
      bm = double(Bookmark)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :existing_bookmark_for).and_return(bm)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :where, :first).and_return(double('bookmark', delete: nil, destroyed?: false)) 
     
      xhr :delete, :destroy, :id => 'pleasekillme', :format => :js

      expect(response.code).to eq "500"
    end
  end
  
end
