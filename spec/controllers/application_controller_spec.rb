# -*- encoding : utf-8 -*-
require 'spec_helper'

describe ApplicationController do
  include Devise::TestHelpers

  describe "#blacklight_config" do

    it "should provide a default blacklight_config everywhere" do
      controller.blacklight_config.should == CatalogController.blacklight_config
    end
  end

end

