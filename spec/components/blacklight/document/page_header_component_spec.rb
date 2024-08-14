# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Document::PageHeaderComponent, type: :component do
  subject(:component) { described_class.new(document: document, search_context: search_context, search_session: current_search_session) }

  let(:show_header_tools_component) { Class.new(Blacklight::Document::ShowToolsComponent) }

  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:document) { SolrDocument.new(id: 'x', title_tsim: 'Title') }

  let(:blacklight_config) do
    CatalogController.blacklight_config.deep_copy
  end

  # rubocop:disable RSpec/SubjectStub
  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive_messages(blacklight_config: blacklight_config)
    allow(controller).to receive(:current_search_session).and_return(double(id: document.id))
    controller.class.helper_method :current_search_session
    allow(controller).to receive_messages(controller_name: 'catalog', link_to_previous_document: '', link_to_next_document: '')
    allow(view_context).to receive_messages(search_context: search_context, search_session: current_search_session, current_search_session: current_search_session)
    allow(component).to receive(:render).and_call_original
    allow(component).to receive(:render).with(an_instance_of(show_header_tools_component)).and_return('tool component content')
    replace_hash = { 'application/_start_over.html.erb' => 'Start Over' }
    if Rails.version.to_f >= 7.1
      controller.prepend_view_path(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for(replace_hash))
    else
      view_context.view_paths.unshift(RSpec::Rails::ViewExampleGroup::StubResolverCache.resolver_for(replace_hash))
    end
  end
  # rubocop:enable RSpec/SubjectStub

  context "all variables are empty" do
    let(:search_context) { nil }
    let(:current_search_session) { {} }

    it 'does not render' do
      expect(rendered.native.inner_html).to be_blank
    end

    context 'has header tools' do
      before do
        blacklight_config.show.show_header_tools_component = show_header_tools_component
      end

      it 'renders the tools' do
        expect(rendered).to have_text 'tool component content'
        expect(rendered).to have_css '.row'
      end
    end
  end

  context "has pagination" do
    let(:search_context) { { next: next_doc, prev: prev_doc } }
    let(:prev_doc) { SolrDocument.new(id: '777') }
    let(:next_doc) { SolrDocument.new(id: '888') }
    let(:current_search_session) { { query_params: { q: 'abc' }, 'id' => '123', 'document_id' => document.id } }

    it 'renders pagination' do
      expect(rendered).to have_text 'Previous'
      expect(rendered).to have_text 'Next'
      expect(rendered).to have_text 'Start Over'
      expect(rendered).to have_text 'Back to Search'
    end

    context 'has header tools' do
      before do
        blacklight_config.show.show_header_tools_component = show_header_tools_component
      end

      it 'renders the tools and pagination' do
        expect(rendered).to have_text 'Previous'
        expect(rendered).to have_text 'Next'
        expect(rendered).to have_text 'Start Over'
        expect(rendered).to have_text 'Back to Search'
        expect(rendered).to have_text 'tool component content'
        expect(rendered).to have_css '.row'
      end
    end
  end
end
