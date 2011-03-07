require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "catalog/_sms_form.html.erb" do
  before do
    assigns[:documents] = [mock("document", :get => "fake_value")]
    render :partial => "catalog/sms_form.html.erb"
  end
  describe "SMS form carrier select input" do
    it "should have the prompt value first" do
      response.should have_tag("option:nth-child(1)[value='']")
    end
    #it "should have other values alphabetized" do
      # sorry can't figure out how to get rspec to do this 
    #end
    
  end
  
  
end
