# frozen_string_literal: true
require 'spec_helper'

describe 'Blacklight::Document::ActiveModelShim' do

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
      response.collect {|doc| MockDocument.new(doc, self)}
    end
  end

  before do
    allow(MockDocument.repository).to receive(:find).and_return(MockResponse.new([{id: 1}], {}))
  end
 
  describe "#find" do
   it "should return a document from the repository" do
      expect(MockDocument.find(1)).to be_a MockDocument
      expect(MockDocument.find(1).id).to be 1
    end
  end
end
