require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight do
  
  context "locate_path" do
    
    it "should find app/controllers/application_controller.rb" do
      result = Blacklight.locate_path 'app', 'controllers', 'application_controller.rb'
      result.should_not == nil
    end
    
    it "should not find blah.rb" do
      result = Blacklight.locate_path 'blah.rb'
      result.should == nil
    end
    
  end
  
  context 'root' do
    
    it 'should return the full path to the BL plugin' do
      blroot = File.expand_path(File.join(__FILE__, '..', '..', '..', '..'))
      Blacklight.root.should == blroot
    end
    
  end
  
end
