# -*- encoding : utf-8 -*-
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

    let(:blroot) { File.expand_path(File.join(__FILE__, '..', '..', '..', 'blacklight-core' )) }

    it 'should return the full path to the BL plugin' do
      Blacklight.root.should == blroot
    end
    
    it 'should return the full path to the model directory' do
      Blacklight.models_dir.should == blroot + "/app/models"
    end

    it 'should return the full path to the controllers directory' do
      Blacklight.controllers_dir.should == blroot + "/app/controllers"
    end

  end
  
end
