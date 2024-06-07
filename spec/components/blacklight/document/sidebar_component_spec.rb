# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Document::SidebarComponent, type: :component do
  subject(:component) { described_class.new(presenter: document) }

  let(:view_context) { controller.view_context }
  let(:render) do
    component.render_in(view_context)
  end

  let(:rendered) do
    Capybara::Node::Simple.new(render)
  end

  let(:document) { view_context.document_presenter(presented_document) }

  let(:presented_document) { SolrDocument.new(id: 'x', title_tsim: 'Title') }

  let(:blacklight_config) do
    CatalogController.blacklight_config.deep_copy
  end

  let(:expected_html) { "<div class=\"expected-show_tools\">Expected Content</div>".html_safe }

  before do
    # Every call to view_context returns a different object. This ensures it stays stable.
    allow(controller).to receive_messages(view_context: view_context, blacklight_config: blacklight_config)
  end

  describe '#render_show_tools' do
    # rubocop:disable RSpec/SubjectStub
    before do
      allow(component).to receive(:render).with(an_instance_of(Blacklight::Document::MoreLikeThisComponent)).and_return("")
    end

    context "without a configured ShowTools component" do
      before do
        allow(component).to receive(:render).with('show_tools', document: presented_document, silence_deprecation: false).and_return(expected_html)
      end

      it 'renders show_tools partial' do
        expect(rendered).to have_css 'div[@class="expected-show_tools"]'
      end
    end

    context "with a configured ShowTools component" do
      let(:show_tools_component) { Class.new(Blacklight::Document::ShowToolsComponent) }

      before do
        blacklight_config.show.show_tools_component = show_tools_component
        allow(component).to receive(:render).with(an_instance_of(show_tools_component)).and_return(expected_html)
      end

      it 'renders configured show_tools component' do
        expect(rendered).to have_css 'div[@class="expected-show_tools"]'
      end
    end
    # rubocop:enable RSpec/SubjectStub
  end
end
