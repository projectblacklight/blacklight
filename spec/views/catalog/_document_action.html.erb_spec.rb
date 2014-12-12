require 'spec_helper'

describe 'catalog/_document_action' do
  let(:document_action_config) { Blacklight::Configuration::ToolConfig.new(tool_config) }
  let(:document) { SolrDocument.new(id: '123') }

  before do
    allow(view).to receive_messages(controller_name: 'catalog')
    render 'catalog/document_action', document_action_config: document_action_config, document: document
  end

  context "for refworks" do
    let(:tool_config) { { if: :render_refworks_action?, partial: "document_action",
      name: :refworks, key: :refworks, modal: false } }

    it "should not be modal" do
      expect(rendered).to have_link('Export to Refworks')
      expect(rendered).not_to have_selector('a[data-ajax-modal]')
    end
  end
end
