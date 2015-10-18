require 'spec_helper'

describe "Blacklight::Document::Email" do
  before(:all) do
    SolrDocument.use_extension( Blacklight::Document::Sms )
  end
  it "should only return values that are available in the field semantics" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>"My Title", :author_display=>"Joe Schmoe"})
    sms_text = doc.to_sms_text
    expect(sms_text).to match(/My Title by Joe Schmoe/)
  end
  it "should handle multi-values fields correctly and only take the first" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>["My Title", "My Alt. Title"]})
    sms_text = doc.to_sms_text
    expect(sms_text).to match(/My Title/)
    expect(sms_text).to_not match(/My Alt\. Title/)
  end
  it "should return nil if there are no valid field semantics to build the email body from" do
    doc = SolrDocument.new({:id=>"1234"})
    expect(doc.to_sms_text).to be_nil
  end
end

