# -*- encoding : utf-8 -*-
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
      @search = Search.new
      @search.user_id = 1
      @search.save

      expect(@search).to be_saved
    end
    it "should be false when user_id is NULL or less than 1" do
      @search = Search.create
      expect(@search).not_to be_saved
    end
  end
  
  describe "delete_old_searches" do
    it "should throw an ArgumentError if days_old is not a number" do
      expect { Search.delete_old_searches("blah") }.to raise_error(ArgumentError)
    end
    it "should throw an ArgumentError if days_old is equal to 0" do
      expect { Search.delete_old_searches(0) }.to raise_error(ArgumentError)
    end
    it "should throw an ArgumentError if days_old is less than 0" do
      expect { Search.delete_old_searches(-1) }.to raise_error(ArgumentError)
    end
    it "should destroy searches with no user_id that are older than X days" do
      Search.destroy_all
      days_old = 7
      unsaved_search_today = Search.new
      unsaved_search_today.user_id = nil
      unsaved_search_today.created_at = Date.today
      unsaved_search_today.save

      unsaved_search_past = Search.new
      unsaved_search_past.user_id = nil
      unsaved_search_past.created_at = Date.today - (days_old + 1).days
      unsaved_search_past.save

      saved_search_today = Search.new
      saved_search_today.user_id = 1
      saved_search_today.created_at = Date.today
      saved_search_today.save

      saved_search_past = Search.new
      saved_search_past.user_id = 1
      saved_search_past.created_at = Date.today - (days_old + 1).days
      saved_search_past.save

      expect do
        Search.delete_old_searches(days_old)
      end.to change(Search, :count).by(-1)
    end
    
  end
  
end
