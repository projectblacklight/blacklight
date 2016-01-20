# frozen_string_literal: true
require 'spec_helper'

describe Search do
  let(:user) { User.create! email: 'xyz@example.com', password: 'xyz12345'}
  describe "query_params" do
    before(:each) do
      @search = Search.new(user: user)
      @query_params = { :q => "query", :f => "facet" }
    end

    it "can save and retrieve the hash" do
      @search.query_params = @query_params
      @search.save!
      expect(Search.find(@search.id).query_params).to eq @query_params
    end
  end

  describe "saved?" do
    it "is true when user_id is not NULL and greater than 0" do
      @search = Search.new(user: user)
      @search.save!

      expect(@search).to be_saved
    end
    it "should be false when user_id is NULL or less than 1" do
      @search = Search.create
      expect(@search).not_to be_saved
    end
  end

  describe "delete_old_searches" do
    it "throws an ArgumentError if days_old is not a number" do
      expect { Search.delete_old_searches("blah") }.to raise_error(ArgumentError)
    end

    it "throws an ArgumentError if days_old is equal to 0" do
      expect { Search.delete_old_searches(0) }.to raise_error(ArgumentError)
    end

    it "throws an ArgumentError if days_old is less than 0" do
      expect { Search.delete_old_searches(-1) }.to raise_error(ArgumentError)
    end

    it "destroy searches with no user_id that are older than X days" do
      Search.destroy_all
      days_old = 7
      Search.create!(created_at: Date.today)
      Search.create!(created_at: Date.today - (days_old + 1).days)
      Search.create!(user: user, created_at: Date.today)
      Search.create!(user: user, created_at: Date.today - (days_old + 1).days)

      expect do
        Search.delete_old_searches(days_old)
      end.to change(Search, :count).by(-1)
    end
  end
end
