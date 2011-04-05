require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe BookmarksController do
  before(:each) do
    # you must activate authlogic in order to test any authentication methods
    activate_authlogic
    @user = User.create!(:password => "password", :password_confirmation => "password", :login => "foo", :email => "foo@bar.com")
    @user_session = UserSession.create!(:password => "password", :login => "foo")
    request.env["HTTP_REFERER"] = "/"
  end

  describe "update" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      activate_authlogic
    end

    it "should create a new bookmark" do
      put :update, :bookmark => {}, :id => 'A'
      response.should be_redirect
      @user.bookmarks.size.should == 1
      @user.bookmarks.first.document_id.should == 'A'
    end

    it "should update an existing bookmark with new values" do
      @user.bookmarks.create! :document_id=> 'A', :title => 'Old Title'

      put :update, :bookmark => {:title => 'New Title'}, :id => 'A'
      response.should be_redirect
      @user.bookmarks.first.title.should == 'New Title'

    end

  end

  describe "index" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      activate_authlogic
    end

    it "should render with no bookmarks" do
      get :index
      response.should be_success
    end

    it "should list user bookmarks" do
      75.times { @user.bookmarks.create! }
      @user.bookmarks.size.should == 75
      get :index
      assigns[:bookmarks].should be_a_kind_of(WillPaginate::Collection)
      assigns[:bookmarks].size.should == 30
      assigns[:bookmarks].total_entries.should == 75
      assigns[:bookmarks].per_page.should == 30
      assigns[:bookmarks].current_page.should == 1
    end

    it "should paginate user bookmarks" do
      75.times { @user.bookmarks.create! }
      @user.bookmarks.size.should == 75

      get :index, :page => 3

      assigns[:bookmarks].size.should == 15
      assigns[:bookmarks].current_page.should == 3

    end
  end

  describe "create" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      activate_authlogic
    end

    it "should create a single bookmark" do
      post :create, :bookmark => { :document_id => 'A' }

      response.should be_redirect
      @user.bookmarks.size.should == 1
    end

    it "should create a batch of bookmarks" do
      post :create, :bookmarks => ('A'..'F').map { |doc_id| { :document_id => doc_id } }

      response.should be_redirect
      @user.bookmarks.size.should == 6
    end

  end

  describe "destroy" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      activate_authlogic
    end

    it "should clear bookmarks" do
      bookmark = @user.bookmarks.create! :document_id => 'A'
      delete :destroy, :id => 'A'

      response.should be_redirect

      Bookmark.find_by_id(bookmark.id).should be_nil
    end
  end

  describe "clear" do
    before(:each) do
      # you must activate authlogic in order to test any authentication methods
      activate_authlogic
    end

    it "should clear bookmarks" do
      @user.bookmarks.create!
      @user.bookmarks.size.should == 1
      delete :clear
      response.should be_redirect
      @user.bookmarks.size.should == 0
    end
  end

end
