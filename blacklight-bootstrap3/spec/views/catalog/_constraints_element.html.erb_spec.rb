# -*- encoding : utf-8 -*-
require 'spec_helper'

describe "catalog/_constraints_element.html.erb" do
  describe "for simple display" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value"}
    end
    it "should render label and value" do
      rendered.should have_selector("span.appliedFilter.constraint") do |s|
        s.should have_selector "span.filterName", :content => "my label"
        s.should have_selector "span.filterValue", :content => "my value" 
      end
    end
  end

  describe "with remove link" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:remove => "http://remove"}}
    end
    it "should include remove link" do
      rendered.should have_selector("span.appliedFilter") do |s|
        s.should have_selector("a.btnRemove.imgReplace[href='http://remove']")
      end    
    end

    it "should have an accessible remove label" do
      rendered.should have_selector("a.imgReplace") do |s|
        s.should have_content("Remove constraint my label: my value")
      end
    end
  end

  describe "with checkmark suppressed" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:check => false}}
    end
    it "should not include checkmark" do
      rendered.should have_selector("span.appliedFilter") do |s|
        s.should_not have_selector("img[src$='checkmark.gif']")
      end   
    end
  end

  describe "with custom classes" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:classes => ["class1", "class2"]}}
    end
    it "should include them" do
      rendered.should have_selector("span.appliedFilter.constraint.class1.class2")
    end
  end

  describe "with no escaping" do
    before do
      render( :partial => "catalog/constraints_element", :locals => {:label => "<span class='custom_label'>my label</span>", :value => "<span class='custom_value'>my value</span>", :options => {:escape_label => false, :escape_value => false}} )
    end
    it "should not escape key and value" do
      rendered.should have_selector("span.appliedFilter.constraint span.filterName span.custom_label")
      rendered.should have_selector("span.appliedFilter.constraint span.filterValue span.custom_value")
    end

  end
 

end
