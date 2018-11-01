# frozen_string_literal: true

RSpec.describe AlternateController do
  describe "the search results tools" do
    it "inherits tools from CatalogController" do
      expect(described_class.blacklight_config.index.document_actions).to have_key(:bookmark)
    end

    context "when deleting partials from the AlternateController" do
      before do
        described_class.blacklight_config.index.document_actions.delete(:bookmark)
      end

      it "does not affect the CatalogController" do
        expect(described_class.blacklight_config.index.document_actions).to be_empty
        expect(CatalogController.blacklight_config.index.document_actions).to have_key(:bookmark)
      end
    end
  end
end
