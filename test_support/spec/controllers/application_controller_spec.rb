# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe ApplicationController do

# HEAD CONTENT
  describe "head content from variables" do

    describe "#default_html_head" do
      it "should setup js and css defaults" do                

        controller.should_receive(:use_asset_pipeline?).any_number_of_times.and_return(false)
        controller.send(:default_html_head)
        controller.javascript_includes.should include(["jquery-1.4.2.min.js", "jquery-ui-1.8.1.custom.min.js", "blacklight/blacklight"])#find do |item|
        #  item == ["jquery-1.4.2.min.js", "jquery-ui-1.7.2.custom.min.js", "blacklight", "application", "accordion", "lightbox", {:plugin=>:blacklight}]
        #end

        controller.stylesheet_links.should include(["yui", "jquery/ui-lightness/jquery-ui-1.8.1.custom.css", "blacklight/blacklight", {:media=>"all"}])
      end

      it "should support rails 3.1 asset pipeline js and css defaults" do
        controller.should_receive(:use_asset_pipeline?).any_number_of_times.and_return(true)
        controller.send(:default_html_head)
        controller.javascript_includes.should include(["application"])
        controller.stylesheet_links.should include(["application",{:media => 'all'}])
      end
    end
  end

end

