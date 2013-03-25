# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Blacklight::Solr::Document::Email" do
  before(:all) do
    SolrDocument.use_extension( Blacklight::Solr::Document::Email )
  end
  it "should only return values that are available in the field semantics" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>"My Title"})
    email_body = doc.to_email_text
    email_body.should match(/Title: My Title/)
    email_body.should_not match(/Author/)
  end
  it "should handle multi-values fields correctly" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>["My Title", "My Alt. Title"]})
    email_body = doc.to_email_text
    email_body.should match(/Title: My Title My Alt. Title/)
  end
  it "should return nil if there are no valid field semantics to build the email body from" do
    doc = SolrDocument.new({:id=>"1234"})
    doc.to_email_text.should be_nil
  end
end

