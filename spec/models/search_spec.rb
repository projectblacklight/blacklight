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
    it "should destroy searches that are older than X days" do
      Search.destroy_all
      days_old = 7
      unsaved_search_today = Search.new
      unsaved_search_today.created_at = Date.today
      unsaved_search_today.save

      unsaved_search_past = Search.new
      unsaved_search_past.created_at = Date.today - (days_old + 1).days
      unsaved_search_past.save

      lambda do
        Search.delete_old_searches(days_old)
      end.should change(Search, :count).by(-1)
    end
    
  end
  
end
