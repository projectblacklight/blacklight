require 'spec_helper'

describe AlternateController do
  describe "add_index_tools_partial" do
    it "should inherit tools from CatalogController" do
      expect(AlternateController.index_tool_partials).to have_key(:bookmark)
    end

    context "when deleting partials from the AlternateController" do
      before do
        AlternateController.index_tool_partials.delete(:bookmark)
      end
      it "should not affect the CatalogController" do
        expect(AlternateController.index_tool_partials).to be_empty
        expect(CatalogController.index_tool_partials).to have_key(:bookmark)
      end
    end
  end
end
