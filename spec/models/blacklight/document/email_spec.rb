# frozen_string_literal: true
require 'spec_helper'

describe "Blacklight::Document::Email" do
  before(:all) do
    SolrDocument.use_extension( Blacklight::Document::Email )
  end
  it "should only return values that are available in the field semantics" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>"My Title"})
    email_body = doc.to_email_text
    expect(email_body).to match(/Title: My Title/)
    expect(email_body).to_not match(/Author/)
  end
  it "should handle multi-values fields correctly" do
    doc = SolrDocument.new({:id=>"1234", :title_display=>["My Title", "My Alt. Title"]})
    email_body = doc.to_email_text
    expect(email_body).to match(/Title: My Title My Alt. Title/)
  end
  it "should return nil if there are no valid field semantics to build the email body from" do
    doc = SolrDocument.new({:id=>"1234"})
    expect(doc.to_email_text).to be_nil
  end
end

