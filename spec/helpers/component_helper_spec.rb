require 'spec_helper'

describe '#document_action_path' do
  before do
    allow(helper).to receive_messages(controller_name: 'catalog')
  end

  let(:document_action_config) { Blacklight::Configuration::ToolConfig.new(tool_config) }
  let(:document) { SolrDocument.new(id: '123') }

  subject { helper.document_action_path(document_action_config, id: document) }

  context "for endnote" do
    let(:tool_config) { { if: :render_refworks_action?, partial: "document_action",
      name: :endnote, key: :endnote, path: :single_endnote_catalog_path } }

    it { is_expected.to eq '/catalog/123.endnote' }
  end
end
