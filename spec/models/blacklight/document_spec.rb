require 'spec_helper'

describe Blacklight::Document do
  let(:data) { {} }
  subject do
    Class.new do
      include Blacklight::Document
    end.new(data)
  end

  describe "#has?" do
    context "without value constraints" do
      it "should have the field if the field is in the data" do
        data[:x] = true
        expect(subject).to have_field(:x)
      end
      
      it "should not have the field if the field is not in the data" do
        expect(subject).not_to have_field(:x)
      end
    end

    context "with regular value constraints" do
      it "should have the field if the data has that value" do
        data[:x] = true
        expect(subject).to have_field(:x, true)
      end
      
      it "should not have the field if the data does not have that value" do
        data[:x] = false
        expect(subject).not_to have_field(:x, true)
      end

      it "should allow multiple value constraints" do
        data[:x] = false
        expect(subject).to have_field(:x, true, false)
      end

      it "should support multivalued fields" do
        data[:x] = ["a", "b", "c"]
        expect(subject).to have_field(:x, "a")
      end

      it "should support multivalued fields with an array of value constraints" do
        data[:x] = ["a", "b", "c"]
        expect(subject).to have_field(:x, "a", "d")
      end
    end

    context "with regexp value constraints" do
      it "should check if the data matches the constraint" do
        data[:x] = "the quick brown fox"
        expect(subject).to have_field(:x, /fox/)
      end

      it "should support multivalued fields" do
        data[:x] = ["the quick brown fox", "and the lazy dog"]
        expect(subject).to have_field(:x, /fox/)
      end
    end
  end
end