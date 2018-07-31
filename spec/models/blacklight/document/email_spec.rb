# frozen_string_literal: true

RSpec.describe "Blacklight::Document::Email" do
  before(:all) do
    SolrDocument.use_extension(Blacklight::Document::Email)
  end

  it "onlies return values that are available in the field semantics" do
    doc = SolrDocument.new(id: "1234", title_tsim: "My Title")
    email_body = doc.to_email_text
    expect(email_body).to match(/Title: My Title/)
    expect(email_body).not_to match(/Author/)
  end
  it "handles multi-values fields correctly" do
    doc = SolrDocument.new(id: "1234", title_tsim: ["My Title", "My Alt. Title"])
    email_body = doc.to_email_text
    expect(email_body).to match(/Title: My Title My Alt. Title/)
  end
  it "returns nil if there are no valid field semantics to build the email body from" do
    doc = SolrDocument.new(id: "1234")
    expect(doc.to_email_text).to be_nil
  end
end
