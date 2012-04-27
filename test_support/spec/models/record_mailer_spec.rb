# -*- encoding : utf-8 -*-

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe RecordMailer do
  before(:each) do
    RecordMailer.stub(:default) { { :from => 'no-reply@projectblacklight.org' } }
    SolrDocument.use_extension( Blacklight::Solr::Document::Email )
    SolrDocument.use_extension( Blacklight::Solr::Document::Sms )
    document = SolrDocument.new({:id=>"123456", :format=>["book"], :title_display => "The horn", :language_facet => "English", :author_display => "Janetzky, Kurt"})
    @documents = [document]
  end
  describe "email" do
    before(:each) do
      details = {:to => 'test@test.com', :message => "This is my message"}
      @email = RecordMailer.email_record(@documents,details,{:host =>'projectblacklight.org', :protocol => 'https'}) 
    end
    it "should receive the TO paramater and send the email to that address" do
      @email.to.should == ['test@test.com']
    end
    it "should start the subject w/ Item Record:" do
      @email.subject.should =~ /^Item Record:/
    end
    it "should put the title of the item in the subject" do
      @email.subject.should =~ /The horn/
    end
    it "should have the correct from address (w/o the port number)" do
      @email.from.should == ["no-reply@projectblacklight.org"]
    end
    it "should print out the correct body" do
      @email.body.should =~ /Title: The horn/
      @email.body.should =~ /Author: Janetzky, Kurt/
      @email.body.should =~ /projectblacklight.org/
    end
    it "should use https URLs when protocol is set" do
      details = {:to => 'test@test.com', :message => "This is my message"}
      @https_email = RecordMailer.email_record(@documents,details,{:host =>'projectblacklight.org', :protocol => 'https'})
      @https_email.body.should =~ %r|https://projectblacklight.org/|
    end
  end
  
  describe "SMS" do
    before(:each) do
      details = {:to => '5555555555', :carrier => 'att'}
      @sms = RecordMailer.sms_record(@documents,details,{:host =>'projectblacklight.org:3000'})
    end
    it "should create the correct TO address for the SMS email" do
      @sms.to.should == ['5555555555@txt.att.net']
    end
    it "should not have a subject" do
      @sms.subject.should == "" unless @sms.subject.nil?
    end
    it "should have the correct from address (w/o the port number)" do
      @sms.from.should == ["no-reply@projectblacklight.org"]
    end
    it "should print out the correct body" do
      @sms.body.should =~ /The horn/
      @sms.body.should =~ /by Janetzky, Kurt/
      @sms.body.should =~ /projectblacklight.org:300/      
    end
    it "should use https URL when protocol is set" do
      details = {:to => '5555555555', :carrier => 'att'}
      @https_sms = RecordMailer.sms_record(@documents,details,{:host =>'projectblacklight.org', :protocol => 'https'})
      @https_sms.body.should =~ %r|https://projectblacklight.org/|
    end
  end

end
