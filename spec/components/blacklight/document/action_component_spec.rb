# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Document::ActionComponent, type: :component do
  subject(:component) { described_class.new(document: document, action: action, **attr) }

  let(:action) { Blacklight::Configuration::ToolConfig.new(key: 'some_tool', name: 'some_tool', component: true) }
  let(:document) do
    SolrDocument.new(
      id: 'x'
    )
  end
  let(:attr) { {} }
  let(:view_context) { vc_test_controller.view_context }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(vc_test_controller).to receive_messages(view_context: view_context)
  end

  context 'with a configured path' do
    before do
      allow(view_context).to receive(:some_tool_solr_document_path).with(document, { only_path: true }).and_return('/asdf')

      render_inline component
    end

    it 'renders an action link' do
      expect(page).to have_link 'Some tool', href: '/asdf'
    end
  end

  context 'with a partial configured' do
    let(:action) { Blacklight::Configuration::ToolConfig.new(name: '', partial: '/some/tool') }

    before do
      allow(view_context).to receive(:render).and_call_original
      allow(view_context).to receive(:render).with(hash_including(partial: '/some/tool'), {}).and_return('tool')

      render_inline component
    end

    it 'render the partial' do
      expect(page).to have_content 'tool'
    end
  end
end
