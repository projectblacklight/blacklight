# frozen_string_literal: true

RSpec.describe Blacklight::Document, api: true do
  subject do
    Class.new do
      include Blacklight::Document
    end.new(data)
  end

  let(:data) { {} }

  describe "#has?" do
    context "without value constraints" do
      it "has the field if the field is in the data" do
        data[:x] = true
        expect(subject).to have_field(:x)
      end

      it "does not have the field if the field is not in the data" do
        expect(subject).not_to have_field(:x)
      end
    end

    context "with regular value constraints" do
      it "has the field if the data has that value" do
        data[:x] = true
        expect(subject).to have_field(:x, true)
      end

      it "does not have the field if the data does not have that value" do
        data[:x] = false
        expect(subject).not_to have_field(:x, true)
      end

      it "allows multiple value constraints" do
        data[:x] = false
        expect(subject).to have_field(:x, true, false)
      end

      it "supports multivalued fields" do
        data[:x] = %w[a b c]
        expect(subject).to have_field(:x, "a")
      end

      it "supports multivalued fields with an array of value constraints" do
        data[:x] = %w[a b c]
        expect(subject).to have_field(:x, "a", "d")
      end
    end

    context "with regexp value constraints" do
      it "checks if the data matches the constraint" do
        data[:x] = "the quick brown fox"
        expect(subject).to have_field(:x, /fox/)
      end

      it "supports multivalued fields" do
        data[:x] = ["the quick brown fox", "and the lazy dog"]
        expect(subject).to have_field(:x, /fox/)
      end
    end
  end

  describe "#to_global_id" do
    class MockDocument
      include Blacklight::Document
      include Blacklight::Document::ActiveModelShim
    end

    class MockResponse
      attr_reader :response, :params

      def initialize(response, params)
        @response = response
        @params = params
      end

      def documents
        response.collect { |doc| MockDocument.new(doc, self) }
      end
    end

    before do
      allow(MockDocument).to receive(:repository).and_return(instance_double(Blacklight::Solr::Repository, find: MockResponse.new([{ id: 1 }], {})))
    end

    it "has a globalid" do
      expect(MockDocument.find(1).to_global_id).to be_a GlobalID
    end
  end
end
