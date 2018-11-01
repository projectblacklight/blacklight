# frozen_string_literal: true

RSpec.describe 'Blacklight::Document::ActiveModelShim', api: true do
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
    allow(MockDocument).to receive(:repository).and_return(double(find: MockResponse.new([{ id: 1 }], {})))
  end

  describe "#find" do
    it "returns a document from the repository" do
      expect(MockDocument.find(1)).to be_a MockDocument
      expect(MockDocument.find(1).id).to be 1
    end
  end

  describe "#==" do
    it 'is equal for the same id' do
      expect(MockDocument.new(id: 1) == MockDocument.new(id: 1)).to eq true
    end

    it 'is not equal if the ids differ' do
      expect(MockDocument.new(id: 1) == MockDocument.new(id: 2)).to eq false
    end
  end
end
