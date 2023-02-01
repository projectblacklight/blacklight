# frozen_string_literal: true

RSpec.describe RecordMailer do
  let(:config) do
    Blacklight::Configuration.new do |config|
      config.email.title_field = 'title_tsim'
      config.add_email_field 'title_tsim', label: 'Title'
      config.add_email_field "author_tsim", label: 'Author'
      config.add_email_field "language_ssim", label: 'Language'
      config.add_email_field "format", label: 'Format'

      config.add_sms_field 'title_tsim', label: 'Title'
      config.add_sms_field "author_tsim", label: 'Author'
    end
  end

  let(:document) do
    SolrDocument.new(id: "123456", format: ["book"], title_tsim: "The horn", language_ssim: "English", author_tsim: "Janetzky, Kurt")
  end

  before do
    allow(described_class).to receive(:default).and_return(from: 'no-reply@projectblacklight.org')
    @documents = [document]
  end

  describe "email" do
    subject(:email) do
      described_class.email_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
    end

    let(:details) do
      { to: 'test@test.com', message: "This is my message", config: config }
    end

    it "receives the TO paramater and send the email to that address" do
      expect(email.to).to include 'test@test.com'
    end

    it "starts the subject w/ Item Record:" do
      expect(email.subject).to match /^Item Record:/
    end

    it "puts the title of the item in the subject" do
      expect(email.subject).to match /The horn/
    end

    it "has the correct from address (w/o the port number)" do
      expect(email.from).to include "no-reply@projectblacklight.org"
    end

    it "prints out the correct body" do
      expect(email.body).to match /Title: The horn/
      expect(email.body).to match /Author: Janetzky, Kurt/
      expect(email.body).to match /projectblacklight.org/
    end

    it "uses https URLs when protocol is set" do
      details = { to: 'test@test.com', message: "This is my message" }
      @https_email = described_class.email_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
      expect(@https_email.body).to match %r{https://projectblacklight.org/}
    end

    context "email title_field is configured and multi valued" do
      let(:document) { SolrDocument.new(id: "123456", foo: ["Fizz Fizz", "Fuzz Fuzz"], format: ["book"], title_tsim: "The horn", language_ssim: "English", author_tsim: "Janetzky, Kurt") }

      before do
        config.email.title_field = "foo"
      end

      it "uses configured email title_field" do
        expect(email.subject).to eq 'Item Record: Fizz Fizz and Fuzz Fuzz'
      end
    end

    context "email title_field is configured and single valued" do
      let(:document) { SolrDocument.new(id: "123456", foo: "Fizz Fizz", format: ["book"], title_tsim: "The horn", language_ssim: "English", author_tsim: "Janetzky, Kurt") }

      before do
        config.email.title_field = "foo"
      end

      it "uses configured email title_field" do
        expect(email.subject).to eq 'Item Record: Fizz Fizz'
      end
    end
  end

  describe "SMS" do
    before do
      details = { to: '5555555555@txt.att.net', config: config }
      @sms = described_class.sms_record(@documents, details, host: 'projectblacklight.org:3000')
    end

    it "creates the correct TO address for the SMS email" do
      expect(@sms.to).to include '5555555555@txt.att.net'
    end

    it "does not have a subject" do
      expect(@sms.subject).to be_blank
    end

    it "has the correct from address (w/o the port number)" do
      expect(@sms.from).to include "no-reply@projectblacklight.org"
    end

    it "prints out the correct body" do
      expect(@sms.body).to match /Title: The horn/
      expect(@sms.body).to match /Author: Janetzky, Kurt/
      expect(@sms.body).to match /projectblacklight.org:3000/
    end

    it "uses https URL when protocol is set" do
      details = { to: '5555555555@txt.att.net' }
      @https_sms = described_class.sms_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
      expect(@https_sms.body).to match %r{https://projectblacklight.org/}
    end
  end
end
