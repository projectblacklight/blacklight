# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::SearchContext::ClientItemPaginationComponent, type: :component do
  subject(:render) { instance.render_in(view_context) }

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:counter) { nil }
  let(:instance) { described_class.new(search_context: { counter: counter }) }
  let(:view_context) { controller.view_context }

  before do
    view_context.view_paths.unshift(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for('application/_start_over.html.erb' => 'start over'))
    allow(view_context).to receive(:link_back_to_catalog).with(any_args)
  end

  it 'is blank without counter param' do
    expect(render).to be_blank
  end

  context 'with counter param' do
    let(:counter) { 1 }

    it 'is not blank' do
      expect(render).not_to be_blank
    end

    it 'has spans that will be populated dynamically by the client' do
      expect(rendered).to have_selector 'span[class="pagination-counter-delimited"]'
      expect(rendered).to have_selector 'span[class="pagination-total-delimited"]'
    end
  end
end
