require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe Blacklight do

  context "solr_config" do
    before(:each) do
      # FIXME Blacklight.init is called before reaching this step..
      Blacklight.solr_config = nil
    end

    it "should load solr config from solr.yml" do
      File.should_receive(:open).with(/solr.yml/).and_return({RAILS_ENV => {}}.to_yaml)
      Blacklight.solr_config.should be_a_kind_of(Hash)
    end

    it "should cache the results of the solr.yml file" do
      File.should_receive(:open).with(/solr.yml/).and_return({RAILS_ENV => {}}.to_yaml)
      Blacklight.solr_config
      Blacklight.solr_config
    end

    it "should load the solr config for the current RAILS_ENV" do
      File.should_receive(:open).with(/solr.yml/).and_return({ 'fake_rails_env' => { :url => 'http://fake.url' }, RAILS_ENV => { :url => 'http://local.solr.server'} }.to_yaml)
      Blacklight.solr_config[:url].should == 'http://local.solr.server'
  end

    it "should raise an exception if no solr configuration is available for the current RAILS_ENV" do
      File.should_receive(:open).with(/solr.yml/).and_return('zzz' => { :url => 'http://local.solr.server'}.to_yaml )
      lambda { Blacklight.solr_config }.should raise_exception
end

    it "should accept any solr configuration" do
      File.should_receive(:open).with(/solr.yml/).and_return({ RAILS_ENV => { :url => 'http://local.solr.server', :proxy => 'http://proxy.solr.server'} }.to_yaml)
      Blacklight.solr_config[:url].should == 'http://local.solr.server'
      Blacklight.solr_config[:proxy].should == 'http://proxy.solr.server'
    end

    it "should be overridable" do
      File.should_not_receive(:open)
      Blacklight.solr_config = { :url => 'http://local.solr.server'}

      Blacklight.solr_config[:url].should == 'http://local.solr.server'

    end
  end

  context "solr" do
    before(:each) do
      # FIXME Blacklight.init is called before reaching this step..
      Blacklight.solr = nil
    end

    it "should connect to solr" do
      Blacklight.should_receive(:solr_config).and_return({ :url => 'http://local.solr.server'})
      Blacklight.solr.should be_a_kind_of(RSolr::Client)
    end

    it "should be overridable" do
      Blacklight.should_not_receive(:solr_config)
      Blacklight.solr = 'something else'
      Blacklight.solr.should == 'something else'
    end
  end
  
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
      blroot = File.expand_path(File.join(__FILE__, '..', '..', '..'))
      Blacklight.root.should == blroot
    end
    
  end
  
end
