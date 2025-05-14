# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Document::GroupComponent, type: :component do
  subject(:component) { described_class.new(group: group, **attr) }

  let(:attr) { {} }
  let(:view_context) { vc_test_controller.view_context }
  let(:docs) { 10.times.map { SolrDocument.new } }

  let(:group) do
    instance_double(Blacklight::Solr::Response::Group, key: 'group1', field: 'group_field', total: 15, docs: docs)
  end

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(vc_test_controller).to receive_messages(view_context: view_context)
    allow(view_context).to receive(:render_document_index).with(docs).and_return('results')
    render_inline component
  end

  it 'renders the group with a header' do
    expect(page).to have_css 'div.group'
    expect(page).to have_css 'h2', text: 'group1'
    expect(page).to have_no_link 'more'
  end

  it 'renders the group documents' do
    expect(page).to have_content 'results'
  end

  context 'with a limit applied' do
    let(:attr) { { group_limit: 5 } }

    it 'renders a control to see more results' do
      expect(page).to have_link 'more'
    end
  end
end
