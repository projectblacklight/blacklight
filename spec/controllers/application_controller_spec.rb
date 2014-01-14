require 'spec_helper'

describe ApplicationController do
  include Devise::TestHelpers

  describe "#blacklight_config" do

    it "should provide a default blacklight_config everywhere" do
      expect(controller.blacklight_config).to eq CatalogController.blacklight_config
    end
  end

end

