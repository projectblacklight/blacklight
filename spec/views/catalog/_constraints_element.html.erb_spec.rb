require File.expand_path(File.dirname(__FILE__) + '/../../spec_helper')

describe "catalog/_constraints_element.html.erb" do
  describe "for simple display" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value"}
    end

    it "should render label and value" do
      response.should have_tag("span.appliedFilter.constraint") do
        with_tag("span.filterName", :text => "my label")
        with_tag("span.filterValue", :text => "my value")
      end
    end
    it "should render checkmark" do      
      response.should have_tag("span.appliedFilter") do
        with_tag("img[src$=checkmark.gif][alt='']")
      end
    end
  end

  describe "with remove link" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:remove => "http://remove"}}
    end
    it "should include remove link" do
      response.should have_tag("span.appliedFilter") do
        with_tag("a.btnRemove.imgReplace[href='http://remove']")
      end    
    end
  end

  describe "with checkmark suppressed" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:check => false}}
    end
    it "should not include checkmark" do
      response.should have_tag("span.appliedFilter") do
        without_tag("img[src$=checkmark.gif]")
      end   
    end
  end

  describe "with custom classes" do
    before do
      render :partial => "catalog/constraints_element", :locals => {:label => "my label", :value => "my value", :options => {:classes => ["class1", "class2"]}}
    end
    it "should include them" do
      response.should have_tag("span.appliedFilter.constraint.class1.class2")
    end
  end

  describe "with no escaping" do
    before do
      render( :partial => "catalog/constraints_element", :locals => {:label => "<span class='custom_label'>my label</span>", :value => "<span class='custom_value'>my value</span>", :options => {:escape_label => false, :escape_value => false}} )
    end
    it "should not escape key and value" do
      response.should have_tag("span.appliedFilter.constraint span.filterName span.custom_label")
      response.should have_tag("span.appliedFilter.constraint span.filterValue span.custom_value")
    end

  end
 

end
