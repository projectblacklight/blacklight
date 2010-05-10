require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')

describe ApplicationController do

# HEAD CONTENT
  describe "head content from variables" do
    it "should include #default_html_head before_filter" do
       controller.class.filter_chain.to_a.find {|f| f.method == :default_html_head && f.options=={} }.should_not be_nil
    end
    describe "#default_html_head" do
      before(:each) do
        controller.send(:default_html_head)
      end
      it "should setup js and css defaults" do
        controller.javascript_includes.should include(["jquery-1.4.2.min.js", "jquery-ui-1.8.1.custom.min.js", "blacklight", "application", "accordion", "lightbox", {:plugin=>:blacklight}])#find do |item|
        #  item == ["jquery-1.4.2.min.js", "jquery-ui-1.7.2.custom.min.js", "blacklight", "application", "accordion", "lightbox", {:plugin=>:blacklight}]
        #end

        controller.stylesheet_links.should include(["yui", "jquery/ui-lightness/jquery-ui-1.8.1.custom.css", "application", {:media=>"all", :plugin=>:blacklight}])
      end
    end        
  end

end
