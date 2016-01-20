# frozen_string_literal: true
require 'spec_helper'

describe "catalog/_constraints_element.html.erb" do
  describe "for simple display" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value"}
    end
    it "should render label and value" do
      expect(rendered).to have_selector("span.appliedFilter.constraint") do |s|
        expect(s).to have_css("span.constraint-value")
        expect(s).to_not have_css("a.constraint-value")
        expect(s).to have_selector "span.filterName", :content => "my label"
        expect(s).to have_selector "span.filterValue", :content => "my value"
      end
    end
  end

  describe "with remove link" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:remove => "http://remove"}}
    end
    it "should include remove link" do
      expect(rendered).to have_selector("span.appliedFilter") do |s|
        expect(s).to have_selector(".remove[href='http://remove']")
      end
    end

    it "should have an accessible remove label" do
      expect(rendered).to have_selector(".remove") do |s|
        expect(s).to have_content("Remove constraint my label: my value")
      end
    end
  end

  describe "with custom classes" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:classes => ["class1", "class2"]}}
    end
    it "should include them" do
      expect(rendered).to have_selector("span.appliedFilter.constraint.class1.class2")
    end
  end

  describe "with no escaping" do
    before do
      render( :partial => "catalog/constraints_element", :locals => {:label => "<span class='custom_label'>my label</span>".html_safe, :value => "<span class='custom_value'>my value</span>".html_safe} )
    end
    it "should not escape key and value" do
      expect(rendered).to have_selector("span.appliedFilter.constraint span.filterName span.custom_label")
      expect(rendered).to have_selector("span.appliedFilter.constraint span.filterValue span.custom_value")
    end

  end


end
