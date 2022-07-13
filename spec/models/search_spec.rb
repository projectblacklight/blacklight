# frozen_string_literal: true

RSpec.describe Search do
  let(:search) { described_class.new(user: user) }
  let(:user) { User.create! email: 'xyz@example.com', password: 'xyz12345' }
  let(:hash_params) { { q: "query", f: { facet: "filter" } } }
  let(:query_params) { hash_params }

  describe "query_params" do
    shared_examples "persisting query_params" do
      it "can save and retrieve the hash" do
        search.query_params = query_params
        search.save!
        expect(described_class.find(search.id).query_params).to eq query_params.with_indifferent_access
      end
    end

    context "are an indifferent hash" do
      include_context "persisting query_params" do
        let(:query_params) { hash_params.with_indifferent_access }
      end
    end

    context "are a string-keyed hash" do
      include_context "persisting query_params" do
        let(:query_params) { hash_params.with_indifferent_access.to_hash }
      end
    end

    context "include symbol keys" do
      include_context "persisting query_params" do
        let(:query_params) { hash_params }
      end
    end
  end

  describe "saved?" do
    it "is true when user_id is not NULL and greater than 0" do
      search.save!
      expect(search).to be_saved
    end

    context "when user_id is NULL or less than 1" do
      let(:search) { described_class.create }

      it "is false" do
        expect(search).not_to be_saved
      end
    end
  end

  describe "delete_old_searches" do
    it "throws an ArgumentError if days_old is not a number" do
      expect { described_class.delete_old_searches("blah") }.to raise_error(ArgumentError)
    end

    it "throws an ArgumentError if days_old is equal to 0" do
      expect { described_class.delete_old_searches(0) }.to raise_error(ArgumentError)
    end

    it "throws an ArgumentError if days_old is less than 0" do
      expect { described_class.delete_old_searches(-1) }.to raise_error(ArgumentError)
    end

    it "destroy searches with no user_id that are older than X days" do
      described_class.destroy_all
      days_old = 7
      described_class.create!(created_at: Date.today)
      described_class.create!(created_at: Date.today - (days_old + 1).days)
      described_class.create!(user: user, created_at: Date.today)
      described_class.create!(user: user, created_at: Date.today - (days_old + 1).days)

      expect do
        described_class.delete_old_searches(days_old)
      end.to change(described_class, :count).by(-1)
    end
  end
end
