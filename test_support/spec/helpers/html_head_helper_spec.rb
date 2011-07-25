require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe HtmlHeadHelper do
  describe "render_stylesheet_links" do
    def stylesheet_links
      [ 
        ["my_stylesheet", {:plugin => :blacklight}],
        ["other_stylesheet"]
      ]
    end
    it "should render stylesheets specified in controller #stylesheet_links" do
      html = render_stylesheet_includes      
      html.should have_selector("link[href='/stylesheets/my_stylesheet.css'][rel='stylesheet'][type='text/css']")
      html.should have_selector("link[href='/stylesheets/other_stylesheet.css'][rel='stylesheet'][type='text/css']")
      html.html_safe?.should == true
    end
  end
  
  describe "render_js_includes" do
    def javascript_includes
      [ 
        ["some_js.js", {:plugin => :blacklight}],
        ["other_js"]
      ]
    end
    it "should include script tags specified in controller#javascript_includes" do
      html = render_js_includes
      html.should have_selector("script[src='/javascripts/some_js.js'][type='text/javascript']")
      html.should have_selector("script[src='/javascripts/other_js.js'][type='text/javascript']")      

      html.html_safe?.should == true
    end
   end

  describe "render_extra_head_content" do
    def extra_head_content
      ['<link rel="a">', '<link rel="b">']
    end

    it "should include content specified in controller#extra_head_content" do
      html = render_extra_head_content

      html.should have_selector("link[rel=a]")
      html.should have_selector("link[rel=b]")

      html.html_safe?.should == true
    end
  end

   describe "render_head_content" do
    describe "with no methods defined" do
      it "should return empty string without complaint" do
      lambda {render_head_content}.should_not raise_error
      render_head_content.should be_blank
      render_head_content.html_safe?.should == true
      end
    end
    describe "with methods defined" do
      def javascript_includes
        [["my_js"]]
      end
      def stylesheet_links
        [["my_css"]]
      end
      def extra_head_content
        [
          "<madeup_tag></madeup_tag>",
          '<link rel="rel" type="type" href="href">' 
        ]
      end
      before(:each) do
        @output = render_head_content
      end
      it "should include extra_head_content" do
        @output.should have_selector("madeup_tag")
        @output.should have_selector("link[rel=rel][type=type][href=href]")
      end
      it "should include render_javascript_includes" do
        @output.index( render_js_includes ).should_not be_nil
      end
      it "should include render_stylesheet_links" do
        @output.index( render_stylesheet_includes ).should_not be_nil
      end
    end
   end
end
