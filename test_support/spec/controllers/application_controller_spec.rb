# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe ApplicationController do
  include Devise::TestHelpers

# HEAD CONTENT
  describe "head content from variables" do

    describe "#default_html_head" do
      it "should setup js and css defaults" do                
        controller.send(:default_html_head)

        # by default, these should be empty, but left in for backwards compatibility 
        controller.javascript_includes.should be_empty
        controller.stylesheet_links.should be_empty
      end
    end
  end

end

