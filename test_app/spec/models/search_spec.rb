require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Search do
  describe "query_params" do
    before(:each) do
      @search = Search.new
      @query_params = { :q => "query", :f => "facet" }
    end
    it "should accept a Hash as the value and save without error" do
      @search.query_params = @query_params
      assert @search.save
    end
    it "should return a Hash as the value" do
      @search.query_params = @query_params
      assert @search.save
      Search.find(@search.id).query_params.should == @query_params
    end
  end
  
  describe "saved?" do
    it "should be true when user_id is not NULL and greater than 0" do
      @search = Search.create(:user_id => 1)
      @search.saved?.should be_true
    end
    it "should be false when user_id is NULL or less than 1" do
      @search = Search.create
      @search.saved?.should_not be_true
    end
  end
  
  describe "delete_old_searches" do
    it "should throw an ArgumentError if days_old is not a number" do
      lambda { Search.delete_old_searches("blah") }.should raise_error(ArgumentError)
    end
    it "should throw an ArgumentError if days_old is equal to 0" do
      lambda { Search.delete_old_searches(0) }.should raise_error(ArgumentError)
    end
    it "should throw an ArgumentError if days_old is less than 0" do
      lambda { Search.delete_old_searches(-1) }.should raise_error(ArgumentError)
    end
    it "should destroy searches with no user_id that are older than X days" do
      Search.destroy_all
      days_old = 7
      unsaved_search_today = Search.create(:user_id => nil, :created_at => Date.today)
      unsaved_search_past = Search.create(:user_id => nil, :created_at => Date.today - (days_old + 1).days)
      saved_search_today = Search.create(:user_id => 1, :created_at => Date.today)
      saved_search_past = Search.create(:user_id => 1, :created_at => (Date.today - (days_old + 1).days))
      lambda do
        Search.delete_old_searches(days_old)
      end.should change(Search, :count).by(-1)
    end
    
  end
  
end
