# frozen_string_literal: true

RSpec.describe RecordMailer do
  before do
    allow(described_class).to receive(:default).and_return(from: 'no-reply@projectblacklight.org')
    SolrDocument.use_extension(Blacklight::Document::Email)
    SolrDocument.use_extension(Blacklight::Document::Sms)
    document = SolrDocument.new(id: "123456", format: ["book"], title_tsim: "The horn", language_ssim: "English", author_tsim: "Janetzky, Kurt")
    @documents = [document]
  end

  describe "email" do
    before do
      details = { to: 'test@test.com', message: "This is my message" }
      @email = described_class.email_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
    end

    it "receives the TO paramater and send the email to that address" do
      expect(@email.to).to include 'test@test.com'
    end
    it "starts the subject w/ Item Record:" do
      expect(@email.subject).to match /^Item Record:/
    end
    it "puts the title of the item in the subject" do
      expect(@email.subject).to match /The horn/
    end
    it "has the correct from address (w/o the port number)" do
      expect(@email.from).to include "no-reply@projectblacklight.org"
    end
    it "prints out the correct body" do
      expect(@email.body).to match /Title: The horn/
      expect(@email.body).to match /Author: Janetzky, Kurt/
      expect(@email.body).to match /projectblacklight.org/
    end
    it "uses https URLs when protocol is set" do
      details = { to: 'test@test.com', message: "This is my message" }
      @https_email = described_class.email_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
      expect(@https_email.body).to match %r{https://projectblacklight.org/}
    end
  end

  describe "SMS" do
    before do
      details = { to: '5555555555@txt.att.net' }
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
      expect(@sms.body).to match /The horn/
      expect(@sms.body).to match /by Janetzky, Kurt/
      expect(@sms.body).to match /projectblacklight.org:3000/
    end
    it "uses https URL when protocol is set" do
      details = { to: '5555555555@txt.att.net' }
      @https_sms = described_class.sms_record(@documents, details, host: 'projectblacklight.org', protocol: 'https')
      expect(@https_sms.body).to match %r{https://projectblacklight.org/}
    end
  end
end
