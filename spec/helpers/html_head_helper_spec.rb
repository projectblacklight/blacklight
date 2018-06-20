require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe HtmlHeadHelper do
  around(:each) do |example|
    tmp_value = Capybara.ignore_hidden_elements
    Capybara.ignore_hidden_elements = false
    example.run
    Capybara.ignore_hidden_elements = tmp_value
  end

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

      html = Deprecation.silence(Blacklight::HtmlHeadHelperBehavior) do
        helper.render_js_includes
      end

      if Rails::VERSION::MAJOR == 4
        expect(html).to have_selector("script[src='/javascripts/some_js.js']")
        expect(html).to have_selector("script[src='/javascripts/other_js.js']")
      elsif use_asset_pipeline?
        # only for rails 3 with asset pipeline enabled
        expect(html).to have_selector("script[src='/assets/some_js.js'][type='text/javascript']")
        expect(html).to have_selector("script[src='/assets/other_js.js'][type='text/javascript']")
      else
        # rails 3 with asset pipeline disabled
        expect(html).to have_selector("script[src='/javascripts/some_js.js'][type='text/javascript']")
        expect(html).to have_selector("script[src='/javascripts/other_js.js'][type='text/javascript']")
      end

      expect(html.html_safe?).to eq(true)
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

      html = Deprecation.silence(Blacklight::HtmlHeadHelperBehavior) do
        helper.render_stylesheet_includes
      end

      if Rails::VERSION::MAJOR == 4
        expect(html).to have_selector("link[href='/stylesheets/my_stylesheet.css'][rel='stylesheet']")
        expect(html).to have_selector("link[href='/stylesheets/other_stylesheet.css'][rel='stylesheet']")
      elsif use_asset_pipeline?
        expect(html).to have_selector("link[href='/assets/my_stylesheet.css'][rel='stylesheet'][type='text/css']")
        expect(html).to have_selector("link[href='/assets/other_stylesheet.css'][rel='stylesheet'][type='text/css']")
      else
        expect(html).to have_selector("link[href='/stylesheets/my_stylesheet.css'][rel='stylesheet'][type='text/css']")
        expect(html).to have_selector("link[href='/stylesheets/other_stylesheet.css'][rel='stylesheet'][type='text/css']")
      end

      expect(html.html_safe?).to eq(true)
    end
  end

  describe "render_extra_head_content" do
    helper do
      def extra_head_content
        ['<link rel="a">', '<link rel="b">']
      end
    end

    it "should include content specified in controller#extra_head_content" do

      html = Deprecation.silence(Blacklight::HtmlHeadHelperBehavior) do
        helper.render_extra_head_content
      end

      expect(html).to have_selector("link[rel=a]")
      expect(html).to have_selector("link[rel=b]")

      expect(html.html_safe?).to eq(true)
    end
  end

  describe "render_head_content" do
    describe "with no methods defined" do
      it "should return empty string without complaint" do
        Deprecation.silence(Blacklight::HtmlHeadHelperBehavior) do
          expect {helper.render_head_content}.not_to raise_error
          expect(helper.render_head_content).to be_blank
          expect(helper.render_head_content.html_safe?).to eq(true)
        end
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
        expect(helper).to receive(:content_for).with(:head).and_return("<meta keywords=\"foo bar\"/>".html_safe)

        @output = Deprecation.silence(Blacklight::HtmlHeadHelperBehavior) do
          helper.render_head_content
        end
      end
      it "should include extra_head_content" do
        expect(@output).to have_selector("madeup_tag")
        expect(@output).to have_selector("link[rel=rel][type=type][href=href]")
      end
      it "should include render_javascript_includes" do
        if Rails::VERSION::MAJOR == 4
          expect(@output).to have_selector("script[src='/javascripts/my_js.js']")
        else
          expect(@output).to have_selector("script[src='/assets/my_js.js'][type='text/javascript']")
        end
      end
      it "should include render_stylesheet_links" do
        if Rails::VERSION::MAJOR == 4
          expect(@output).to have_selector("link[href='/stylesheets/my_css.css']")
        else
          expect(@output).to have_selector("link[href='/assets/my_css.css'][type='text/css']")
        end
      end
      it "should include content_for :head" do
        expect(@output).to have_selector("meta[keywords]")
      end

      it "should include all head content" do
        expect(helper).to receive(:render_extra_head_content).and_return("".html_safe)
        expect(helper).to receive(:render_js_includes).and_return("".html_safe)
        expect(helper).to receive(:render_stylesheet_includes).and_return("".html_safe)
        expect(helper).to receive(:content_for).with(:head).and_return("".html_safe)

        Deprecation.silence(Blacklight::HtmlHeadHelperBehavior) do
          expect(helper.render_head_content).to be_html_safe
        end
      end
    end
  end

  private
  def use_asset_pipeline?
    Rails::VERSION::MAJOR == 4 || ((Rails::VERSION::MAJOR == 3 and Rails::VERSION::MINOR >= 1) and Rails.application.config.assets.enabled)
  end

end
