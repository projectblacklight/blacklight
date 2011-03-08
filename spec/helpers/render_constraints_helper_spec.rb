require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

# This is NOT currently spec'ing render_constraints_* methods, becuase
# inflexibility in rspec makes it really hard to do so effectively. It would be
# nice, the specs that are there for render_search_to_s could be a model. 
#
# We ARE spec'ing render_search_to_s* versions, which is feasible since they
# don't call any template partials. 
describe RenderConstraintsHelper do

  describe "render_search_to_s_*" do
    describe "render_search_to_s_element" do
      it "should render basic element" do
        response = helper.render_search_to_s_element("key", "value")
        response.should have_tag("span.constraint") do
          with_tag("span.filterName", :text => "key:")
          with_tag("span.filterValue", :text => "value")
        end
        response.html_safe?.should == true
      end
      it "should escape them that need escaping" do
        response = helper.render_search_to_s_element("key>", "value>")
        response.should have_tag("span.constraint") do
          with_tag("span.filterName", :text => "key&gt;:")
          with_tag("span.filterValue", :text => "value&gt;")
        end
        response.html_safe?.should == true
      end
      it "should not escape with options set thus" do
        response = helper.render_search_to_s_element("key>".html_safe, "value>".html_safe)
        response.should have_tag("span.constraint") do
          with_tag("span.filterName", :text => "key>:")
          with_tag("span.filterValue", :text => "value>")
        end
        response.html_safe?.should == true
      end
    end

    describe "render_search_to_s" do
      before do
        @params = {:q => "history", :f => {"some_facet" => ["value1", "value1"],  "other_facet" => ["other1"]}}        
      end
      it "should call lesser methods" do
        # API hooks expect this to be so
        response = helper.render_search_to_s(params)

        response.should include( helper.render_search_to_s_q(params))
        response.should include( helper.render_search_to_s_filters(params))
        response.html_safe?.should == true
      end
    end
    

  
  end

end
