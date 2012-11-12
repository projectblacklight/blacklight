require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight::Solr::Document::MoreLikeThis do
  before(:all) do
    @mock_class = Class.new do
      include Blacklight::Solr::Document
    end
  end
  
  it "should pluck the MoreLikeThis results from the Solr Response" do
    mock_solr_response = mock(:more_like => [{'id' => 'abc'}])
    result = @mock_class.new({:id => '123'}, mock_solr_response).more_like_this
    result.should have(1).item
    result.first.should be_a_kind_of(SolrDocument)
    result.first.id.should == 'abc'
    result.first.solr_response.should == mock_solr_response
  end 
end