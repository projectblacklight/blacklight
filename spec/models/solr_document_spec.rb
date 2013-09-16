# -*- encoding : utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

  describe SolrDocument do
    
    before(:each) do
      
      @solrdoc = SolrDocument.new :id => '00282214', :format => ['Book'], :title_display => 'some-title'

    end
    
    describe "new" do
      it "should take a Hash as the argument" do
        lambda { SolrDocument.new(:id => 1) }.should_not raise_error
      end
    end
    
    describe "access methods" do

      it "should have the right value for title_display" do
        @solrdoc[:title_display].should_not be_nil
      end
      
      it "should have the right value for format" do
        @solrdoc[:format][0].should == 'Book'
      end
      
      it "should provide the item's solr id" do
        @solrdoc.id.should == '00282214'
      end
    end
end