require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe HtmlHeadHelper do

  describe "render_js_includes" do
    helper do 
      def javascript_includes
        [ 
          ["some_js.js", {:plugin => :blacklight}],
          ["other_js"]
        ]
      end
    end
    it "should include script tags specified in controller#javascript_includes" do
      html = helper.render_js_includes

      if Rails::VERSION::MAJOR == 4 
        html.should have_selector("script[src='/javascripts/some_js.js']")
        html.should have_selector("script[src='/javascripts/other_js.js']")      
      elsif use_asset_pipeline?
        # only for rails 3 with asset pipeline enabled
        html.should have_selector("script[src='/assets/some_js.js'][type='text/javascript']")
        html.should have_selector("script[src='/assets/other_js.js'][type='text/javascript']")
      else
        # rails 3 with asset pipeline disabled
        html.should have_selector("script[src='/javascripts/some_js.js'][type='text/javascript']")
        html.should have_selector("script[src='/javascripts/other_js.js'][type='text/javascript']")      
      end

      html.html_safe?.should == true
    end
  end

  describe "render_stylesheet_links" do
    helper do 
      def stylesheet_links
        [ 
          ["my_stylesheet", {:plugin => :blacklight}],
          ["other_stylesheet"]
        ]
      end
    end
    it "should render stylesheets specified in controller #stylesheet_links" do
      html = helper.render_stylesheet_includes      

      if Rails::VERSION::MAJOR == 4 
        html.should have_selector("link[href='/stylesheets/my_stylesheet.css'][rel='stylesheet']")
        html.should have_selector("link[href='/stylesheets/other_stylesheet.css'][rel='stylesheet']")
      elsif use_asset_pipeline?
        html.should have_selector("link[href='/assets/my_stylesheet.css'][rel='stylesheet'][type='text/css']")
        html.should have_selector("link[href='/assets/other_stylesheet.css'][rel='stylesheet'][type='text/css']")
      else
        html.should have_selector("link[href='/stylesheets/my_stylesheet.css'][rel='stylesheet'][type='text/css']")
        html.should have_selector("link[href='/stylesheets/other_stylesheet.css'][rel='stylesheet'][type='text/css']")
      end

      html.html_safe?.should == true
    end
  end
  
  describe "render_extra_head_content" do
    helper do 
      def extra_head_content
        ['<link rel="a">', '<link rel="b">']
      end
    end

    it "should include content specified in controller#extra_head_content" do
      html = helper.render_extra_head_content

      html.should have_selector("link[rel=a]")
      html.should have_selector("link[rel=b]")

      html.html_safe?.should == true
    end
  end

  describe "render_head_content" do
    describe "with no methods defined" do
      it "should return empty string without complaint" do
      lambda {helper.render_head_content}.should_not raise_error
      helper.render_head_content.should be_blank
      helper.render_head_content.html_safe?.should == true
      end
    end
    describe "with methods defined" do
      helper do 
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
      end
      before(:each) do
        helper.should_receive(:content_for).with(:head).and_return("<meta keywords=\"foo bar\"/>".html_safe)
        @output = helper.render_head_content
      end
      it "should include extra_head_content" do
        @output.should have_selector("madeup_tag")
        @output.should have_selector("link[rel=rel][type=type][href=href]")
      end
      it "should include render_javascript_includes" do
        if Rails::VERSION::MAJOR == 4 
          @output.should have_selector("script[src='/javascripts/my_js.js']")
        else
          @output.should have_selector("script[src='/assets/my_js.js'][type='text/javascript']")
        end
      end
      it "should include render_stylesheet_links" do
        if Rails::VERSION::MAJOR == 4 
          @output.should have_selector("link[href='/stylesheets/my_css.css']")
        else
          @output.should have_selector("link[href='/assets/my_css.css'][type='text/css']")
        end
      end
      it "should include content_for :head" do
        @output.should have_selector("meta[keywords]")
      end

      it "should include all head content" do
        helper.should_receive(:render_extra_head_content).and_return("".html_safe)
        helper.should_receive(:render_js_includes).and_return("".html_safe)
        helper.should_receive(:render_stylesheet_includes).and_return("".html_safe)
        helper.should_receive(:content_for).with(:head).and_return("".html_safe)
        helper.render_head_content.should be_html_safe
      end
    end
  end

  private
  def use_asset_pipeline?
    Rails::VERSION::MAJOR == 4 || ((Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR >= 1) and Rails.application.config.assets.enabled)
  end

end
