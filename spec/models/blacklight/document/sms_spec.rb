# frozen_string_literal: true

RSpec.describe "Blacklight::Document::Email" do
  let(:config) do
    Blacklight::Configuration.new
  end

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

  context "we pass in configuration with sms fields set" do
    it "uses the sms fields for to_sms_text" do
      config.add_sms_field("foo", label: "Foo:")
      config.add_sms_field("bar", label: " by")
      doc = SolrDocument.new(id: "1234", foo: ["Fuzz Fuzz", "Fizz Fizz"], bar: ["Buzz Buzz", "Bizz Bizz"])

      expect(doc.to_sms_text(config)).to eq("Foo: Fuzz Fuzz by Buzz Buzz")
    end
  end

  context "we pass in configuration with sms fields no set" do
    it "falls back on default semantics setup" do
      doc = SolrDocument.new(id: "1234", title_tsim: ["My Title", "My Alt. Title"])
      sms_text = doc.to_sms_text(config)
      expect(sms_text).to match(/My Title/)
      expect(sms_text).not_to match(/My Alt\. Title/)
    end
  end

  context "document field is single valued" do
    it "handles the single value field correctly" do
      config.add_sms_field("foo", label: "Foo:")
      config.add_sms_field("bar", label: " by")
      doc = SolrDocument.new(id: "1234", foo: "Fuzz Fuzz", bar: ["Buzz Buzz", "Bizz Bizz"])

      expect(doc.to_sms_text(config)).to eq("Foo: Fuzz Fuzz by Buzz Buzz")
    end
  end
end
