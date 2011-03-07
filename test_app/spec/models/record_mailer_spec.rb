# encoding: UTF-8

require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')



describe RecordMailer do
  before(:each) do
    @documents = []
    @documents.push(stub_model(SolrDocument, :id => '123456', :to_marc => sample_marc, :[] => 'book'))
  end
  describe "email" do
    before(:each) do
      details = {:to => 'test@test.com', :message => "This is my message"}
      @email = RecordMailer.email_record(@documents,details,'projectblacklight.org','projectblacklight.org:3000')
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
      @email.body.should =~ /Title: The horn /
      @email.body.should =~ /Author: Janetzky, Kurt/
      @email.body.should =~ /projectblacklight.org:3000/
    end
  end
  
  describe "SMS" do
    before(:each) do
      details = {:to => '5555555555', :carrier => 'att'}
      @sms = RecordMailer.sms_record(@documents,details,'projectblacklight.org','projectblacklight.org:3000')
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
  end

  def record_xml
    "<record>
       <leader>01021cam a2200277 a 4500</leader>
       <controlfield tag=\"001\">a1711966</controlfield>
       <controlfield tag=\"003\">SIRSI</controlfield>
       <controlfield tag=\"008\">890421s1988    enka          001 0 eng d</controlfield>
  
       <datafield tag=\"100\" ind1=\"1\" ind2=\" \">
         <subfield code=\"a\">Janetzky, Kurt.</subfield>
       </datafield>
  
       <datafield tag=\"245\" ind1=\"1\" ind2=\"4\">
         <subfield code=\"a\">The horn /</subfield>
         <subfield code=\"c\">Kurt Janetzky and Bernhard Bruchle ; translated from the German by James Chater.</subfield>
       </datafield>
  
       <datafield tag=\"260\" ind1=\" \" ind2=\" \">
         <subfield code=\"a\">London :</subfield>
         <subfield code=\"b\">Batsford,</subfield>
         <subfield code=\"c\">1988.</subfield>
       </datafield>
  
       <datafield tag=\"700\" ind1=\"1\" ind2=\" \">
         <subfield code=\"a\">Brüchle, Bernhard.</subfield>
       </datafield>
    </record>"
  end
  
  def sample_marc
    reader = MARC::XMLReader.new(StringIO.new( record_xml ))
    reader.each {|rec| return rec}
  end
  
end
