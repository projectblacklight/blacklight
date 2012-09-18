# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe SearchHistoryConstraintsHelper do

  before(:all) do
    @config = Blacklight::Configuration.new do |config|
      config.add_search_field 'default_search_field', :label => 'Default'

      config.add_facet_field 'some_facet', :label => 'Some'
      config.add_facet_field 'other_facet', :label => 'Other'
    end
  end

  before(:each) do
    helper.stub(:blacklight_config).and_return(@config)
  end

  describe "render_search_to_s_*" do
    describe "render_search_to_s_element" do
      it "should render basic element" do
        response = helper.render_search_to_s_element("key", "value")
        response.should have_selector("span.constraint")  do |span|
          span.should have_selector("span.filterName", :content => "key:")
          span.should have_selector("span.filterValue", :content => "value")
        end
        response.html_safe?.should == true
      end
      it "should escape them that need escaping" do
        response = helper.render_search_to_s_element("key>", "value>")
        response.should have_selector("span.constraint") do |span|          
          span.should have_selector("span.filterName") do |s2|
            # Note: nokogiri's gettext will unescape the inner html
            # which seems to be what rspecs "contains" method calls on 
            # text nodes - thus the to_s inserted below.
            s2.to_s.should match(/key&gt;:/)
          end
          span.should have_selector("span.filterValue") do |s3|            
            s3.to_s.should match(/value&gt;/)
          end
        end
        response.html_safe?.should == true
      end
      it "should not escape with options set thus" do
        response = helper.render_search_to_s_element("key>", "value>", :escape_key => false, :escape_value => false)
        response.should have_selector("span.constraint") do |span|
          span.should have_selector("span.filterName", :content => "key>:")
          span.should have_selector("span.filterValue", :content => "value>")
        end
        response.html_safe?.should == true
      end
    end

    describe "render_search_to_s" do
      before do
        @params = {:q => "history", :f => {"some_facet" => ["value1", "value1"],  "other_facet" => ["other1"]}}        
      end
      it "should call lesser methods" do
        helper.stub!(:blacklight_config).and_return(@config)
        helper.stub!(:default_search_field).and_return(Blacklight::Configuration::SearchField.new(:key => 'default_search_field', :display_label => 'Default'))
        helper.should_receive(:label_for_search_field).with(nil).any_number_of_times.and_return('')
        # API hooks expect this to be so
        response = helper.render_search_to_s(@params)

        response.should include( helper.render_search_to_s_q(@params))
        response.should include( helper.render_search_to_s_filters(@params))
        response.html_safe?.should == true
      end
    end
    

  
  end

end
