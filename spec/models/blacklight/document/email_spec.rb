# frozen_string_literal: true

RSpec.describe "Blacklight::Document::Email" do
  let(:config) do
    Blacklight::Configuration.new
  end

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

  context "we pass in configuration with email fields set" do
    it "uses the email fields for to_email_text" do
      config.add_email_field("foo", label: "Foo:")
      config.add_email_field("bar", label: "Bar:")
      doc = SolrDocument.new(id: "1234", foo: ["Fuzz Fuzz", "Fizz Fizz"], bar: ["Buzz Buzz", "Bizz Bizz"])

      expect(doc.to_email_text(config)).to eq("Foo: Fuzz Fuzz Fizz Fizz\nBar: Buzz Buzz Bizz Bizz")
    end
  end

  context "we pass in configuration with email fields no set" do
    it "falls back on default semantics setup" do
      doc = SolrDocument.new(id: "1234", title_tsim: ["My Title", "My Alt. Title"])
      email_body = doc.to_email_text(config)
      expect(email_body).to match(/Title: My Title/)
    end
  end

  context "document field is single valued" do
    it "handles the single value field correctly" do
      config.add_email_field("foo", label: "Foo:")
      config.add_email_field("bar", label: "Bar:")
      doc = SolrDocument.new(id: "1234", foo: "Fuzz Fuzz", bar: ["Buzz Buzz", "Bizz Bizz"])

      expect(doc.to_email_text(config)).to eq("Foo: Fuzz Fuzz\nBar: Buzz Buzz Bizz Bizz")
    end
  end
end
