# frozen_string_literal: true
require 'spec_helper'

describe SolrDocument do
  
  before(:each) do
    
    @solrdoc = SolrDocument.new :id => '00282214', :format => ['Book'], :title_display => 'some-title'

  end
  
  describe "new" do
    it "should take a Hash as the argument" do
      expect { SolrDocument.new(:id => 1) }.not_to raise_error
    end
  end
  
  describe "access methods" do

    it "should have the right value for title_display" do
      expect(@solrdoc[:title_display]).not_to be_nil
    end
    
    it "should have the right value for format" do
      expect(@solrdoc[:format][0]).to eq 'Book'
    end
    
    it "should provide the item's solr id" do
      expect(@solrdoc.id).to eq '00282214'
    end
  end
end