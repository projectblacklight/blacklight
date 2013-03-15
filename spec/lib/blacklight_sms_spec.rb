# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe "Blacklight::Solr::Document::Email" do
  before(:all) do
    SolrDocument.use_extension( Blacklight::Solr::Document::Sms )
  end
  it "should only return values that are available in the field semantics" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>"My Title", :author_display=>"Joe Schmoe"})
    sms_text = doc.to_sms_text
    sms_text.should match(/My Title by Joe Schmoe/)
  end
  it "should handle multi-values fields correctly and only take the first" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>["My Title", "My Alt. Title"]})
    sms_text = doc.to_sms_text
    sms_text.should match(/My Title/)
    sms_text.should_not match(/My Alt\. Title/)
  end
  it "should return nil if there are no valid field semantics to build the email body from" do
    doc = SolrDocument.new({:id=>"1234"})
    doc.to_sms_text.should be_nil
  end
end

