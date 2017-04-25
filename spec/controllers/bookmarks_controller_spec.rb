# frozen_string_literal: true

RSpec.describe BookmarksController do
  describe '#blacklight_config' do
    it 'uses POST requests for querying solr' do
      expect(@controller.blacklight_config.http_method).to eq :post
    end
  end

  # jquery 1.9 ajax does error callback if 200 returns empty body. so use 204 instead. 
  describe "update" do
    it "has a 200 status code when creating a new one" do
      put :update, xhr: true, params: { id: '2007020969', format: :js }
      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 1
    end
    
    it "has a 500 status code when create is not success" do
      allow(@controller).to receive_message_chain(:current_or_guest_user, :existing_bookmark_for).and_return(false)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :persisted?).and_return(true)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :where, :exists?).and_return(false)  
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :create).and_return(false)  
      put :update, xhr: true, params: { id: 'iamabooboo', format: :js }
      expect(response.code).to eq "500"
    end
  end
  
  describe "delete" do
    before do
      @controller.send(:current_or_guest_user).save
      @controller.send(:current_or_guest_user).bookmarks.create! document_id: '2007020969', document_type: "SolrDocument"
    end
    
    it "has a 200 status code when delete is success" do
      delete :destroy, xhr: true, params: { id: '2007020969', format: :js }
      expect(response).to be_success
      expect(response.code).to eq "200"
      expect(JSON.parse(response.body)["bookmarks"]["count"]).to eq 0
    end

   it "has a 500 status code when delete is not success" do
      bm = instance_double(Bookmark)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :existing_bookmark_for).and_return(bm)
      allow(@controller).to receive_message_chain(:current_or_guest_user, :bookmarks, :find_by).and_return(instance_double(Bookmark, delete: nil, destroyed?: false))
     
      delete :destroy, xhr: true, params: { id: 'pleasekillme', format: :js }

      expect(response.code).to eq "500"
    end
  end

  describe 'token based users' do
    let(:user) { User.find_or_create_by(email: 'user1@example.com') { |u| u.password = 'password' } }
    let(:current_time) { nil }
    let(:token) { controller.send(:encrypt_user_id, user.id, current_time) }

    before do
      allow(controller).to receive(:fetch).and_return([])
    end

    it 'finds the user from the encrypted token' do
      get :index, params: { encrypted_user_id: token }
      expect(controller.send(:token_user).id).to eq user.id
    end

    context 'created over an hour ago' do
      let(:current_time) { Time.zone.now - 2.hours }

      it 'is expired' do
        get :index, params: { encrypted_user_id: token }
        expect do
          controller.send(:token_user)
        end.to raise_error(Blacklight::Exceptions::ExpiredSessionToken)
      end
    end
  end
end
