# frozen_string_literal: true
require 'spec_helper'

describe AlternateController do
  describe "the search results tools" do
    it "should inherit tools from CatalogController" do
      expect(AlternateController.blacklight_config.index.document_actions).to have_key(:bookmark)
    end

    context "when deleting partials from the AlternateController" do
      before do
        AlternateController.blacklight_config.index.document_actions.delete(:bookmark)
      end
      it "should not affect the CatalogController" do
        expect(AlternateController.blacklight_config.index.document_actions).to be_empty
        expect(CatalogController.blacklight_config.index.document_actions).to have_key(:bookmark)
      end
    end
  end
end
