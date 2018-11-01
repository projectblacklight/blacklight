# frozen_string_literal: true

RSpec.describe "Blacklight::Document::Email" do
  before(:all) do
    SolrDocument.use_extension(Blacklight::Document::Sms)
  end

  it "onlies return values that are available in the field semantics" do
    doc = SolrDocument.new(id: "1234", title_tsim: "My Title", author_tsim: "Joe Schmoe")
    sms_text = doc.to_sms_text
    expect(sms_text).to match(/My Title by Joe Schmoe/)
  end
  it "handles multi-values fields correctly and only take the first" do
    doc = SolrDocument.new(id: "1234", title_tsim: ["My Title", "My Alt. Title"])
    sms_text = doc.to_sms_text
    expect(sms_text).to match(/My Title/)
    expect(sms_text).not_to match(/My Alt\. Title/)
  end
  it "returns nil if there are no valid field semantics to build the email body from" do
    doc = SolrDocument.new(id: "1234")
    expect(doc.to_sms_text).to be_nil
  end
end
