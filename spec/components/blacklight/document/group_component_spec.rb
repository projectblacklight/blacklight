# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Document::GroupComponent, type: :component do
  subject(:component) { described_class.new(group: group, **attr) }

  let(:attr) { {} }
  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:docs) { 10.times.map { double } }

  let(:group) do
    instance_double(Blacklight::Solr::Response::Group, key: 'group1', field: 'group_field', total: 15, docs: docs)
  end

  before do
    allow(view_context).to receive(:render_document_index).with(docs).and_return('results')
  end

  it 'renders the group with a header' do
    expect(rendered).to have_selector 'div.group'
    expect(rendered).to have_selector 'h2', text: 'group1'
    expect(rendered).not_to have_link 'more'
  end

  it 'renders the group documents' do
    expect(rendered).to have_content 'results'
  end

  context 'with a limit applied' do
    let(:attr) { { group_limit: 5 } }

    it 'renders a control to see more results' do
      expect(rendered).to have_link 'more'
    end
  end
end
