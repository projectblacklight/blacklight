# -*- encoding : utf-8 -*-
require File.expand_path(File.dirname(__FILE__) + '/../spec_helper')
describe ApplicationController do
  include Devise::TestHelpers

# HEAD CONTENT
  describe "head content from variables" do

    describe "#default_html_head" do
      it "should setup js and css defaults" do   
        Deprecation.silence(Blacklight::LegacyControllerMethods) do             
          controller.send(:default_html_head)

          # by default, these should be empty, but left in for backwards compatibility 
          expect(controller.javascript_includes).to be_empty
          expect(controller.stylesheet_links).to be_empty
        end
      end
    end

    describe "#blacklight_config" do

      it "should provide a default blacklight_config everywhere" do
        expect(controller.blacklight_config).to eq(CatalogController.blacklight_config)
      end
    end

  end

end

