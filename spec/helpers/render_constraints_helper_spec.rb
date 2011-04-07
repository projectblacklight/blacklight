require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# This is NOT currently spec'ing render_constraints_* methods, becuase
# inflexibility in rspec makes it really hard to do so effectively. It would be
# nice, the specs that are there for render_search_to_s could be a model. 
#
# We ARE spec'ing render_search_to_s* versions, which is feasible since they
# don't call any template partials. 
describe RenderConstraintsHelper do
  include RenderConstraintsHelper

  describe "render_constraints" do
    it "should render constraints for both query and filter" do
      self.should_receive(:render_constraints_query).with({}).and_return("constraints".html_safe)
      self.should_receive(:render_constraints_filters).with({}).and_return("+filters".html_safe)

      result = render_constraints({})
      result.should == "constraints+filters"
      result.should be_html_safe
    end
  end

  describe "render_constraints_query" do
    it "should return any empty string when no query provided" do
      result = render_constraints_query(:q => nil)
      result.should == ""
      result.should be_html_safe
    end

    it "should render a constraint element" do
      self.should_receive(:render_constraint_element).with(nil, "asd", anything()).and_return("asd".html_safe)
      result = render_constraints_query(:q => 'asd')
      result.should == "asd"
      result.should be_html_safe
    end

    it "should render a search field label if the current search field is not the default" do
      Blacklight.should_receive(:label_for_search_field).with("my_fake_search_field").and_return("Label")
      self.should_receive(:render_constraint_element).with("Label", "asd", anything()).and_return("Label: asd".html_safe)
      result = render_constraints_query(:q => 'asd', :search_field => "my_fake_search_field")
      result.should == "Label: asd"
      result.should be_html_safe
    end
  end

  describe "render_constraints_filters" do
    it "should return an empty string when no filters provided" do
      result = render_constraints_filters(:q => nil)
      result.should == ""
      result.should be_html_safe
    end

    it "should return a new-line delimited string of constraint elements for each filter" do
      self.should_receive(:facet_field_labels).and_return({'a' => "A"})
      self.should_receive(:remove_facet_params).with(any_args).and_return("/fake_path")
      self.should_receive(:render_constraint_element).with("A", "asd", anything()).and_return("A: asd".html_safe)

      result = render_constraints_filters(:f => { 'a' => ["asd"] })
      result.should == "A: asd\n"
      result.should be_html_safe
    end
  end

  describe "render_search_to_s_*" do
    describe "render_search_to_s_element" do
      it "should render basic element" do
        result = render_search_to_s_element("key", "value")
        result.should have_tag("span.constraint") do
          with_tag("span.filterName", :text => "key:")
          with_tag("span.filterValue", :text => "value")
        end
        result.should be_html_safe
      end
      it "should escape them that need escaping" do
        result = render_search_to_s_element("key>", "value>")
        result.should have_tag("span.constraint") do
          with_tag("span.filterName", :text => "key&gt;:")
          with_tag("span.filterValue", :text => "value&gt;")
        end
        result.should be_html_safe
      end
      it "should not escape with options set thus" do
        result = render_search_to_s_element("key>".html_safe, "value>".html_safe)
        result.should have_tag("span.constraint") do
          with_tag("span.filterName", :text => "key>:")
          with_tag("span.filterValue", :text => "value>")
        end
        result.should be_html_safe
      end
    end

    describe "render_search_to_s" do
      before do
        @params = {:q => "history", :f => {"some_facet" => ["value1", "value1"],  "other_facet" => ["other1"]}}        
      end
      it "should call lesser methods" do
        # API hooks expect this to be so
        result = render_search_to_s(params)

        result.should include( render_search_to_s_q(params))
        result.should include( render_search_to_s_filters(params))
        result.should be_html_safe
      end
    end
    

  
  end

end
