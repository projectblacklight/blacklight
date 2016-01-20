# frozen_string_literal: true
require 'spec_helper'

describe Blacklight::Solr::Document::MoreLikeThis do
  before(:all) do
    @mock_class = Class.new do
      include Blacklight::Solr::Document
    end
  end
  
  it "should pluck the MoreLikeThis results from the Solr Response" do
    mock_solr_response = double(:more_like => [{'id' => 'abc'}])
    result = @mock_class.new({:id => '123'}, mock_solr_response).more_like_this
    expect(result).to have(1).item
    expect(result.first).to be_a_kind_of(@mock_class)
    expect(result.first.id).to eq 'abc'
    expect(result.first.solr_response).to eq mock_solr_response
  end 
end