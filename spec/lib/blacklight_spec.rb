# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight do

  around :each do |example|
    Deprecation.silence(Blacklight) do
      example.run
    end
  end
  
  context "locate_path" do
    
    it "should find app/controllers/application_controller.rb" do
      result = Blacklight.locate_path 'app', 'controllers', 'application_controller.rb'
      expect(result).not_to eq(nil)
    end
    
    it "should not find blah.rb" do
      result = Blacklight.locate_path 'blah.rb'
      expect(result).to eq(nil)
    end
    
  end
  
  context 'root' do

    before(:all) do
      @blroot = File.expand_path(File.join(__FILE__, '..', '..', '..' ))
    end

    it 'should return the full path to the BL plugin' do
      expect(Blacklight.root).to eq(@blroot)
    end
    
    it 'should return the full path to the model directory' do
      expect(Blacklight.models_dir).to eq(@blroot + "/app/models")
    end

    it 'should return the full path to the controllers directory' do
      expect(Blacklight.controllers_dir).to eq(@blroot + "/app/controllers")
    end

  end
  
end
