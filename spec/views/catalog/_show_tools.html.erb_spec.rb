# frozen_string_literal: true

RSpec.describe "catalog/_show_tools.html.erb" do
  let(:document) { SolrDocument.new id: 'xyz', format: 'a' }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:component) { instance_double(Blacklight::Document::ActionsComponent) }

  before do
    allow(Blacklight::Document::ActionsComponent).to receive(:new).and_return(component)
    allow(view).to receive(:render).with(component)
    allow(view).to receive(:render).with('catalog/show_tools', {}).and_call_original
    assign :response, instance_double(Blacklight::Solr::Response, params: {})
    assign :document, document
    allow(view).to receive(:blacklight_config).and_return blacklight_config
    allow(view).to receive(:has_user_authentication_provider?).and_return false
  end

  describe "document actions" do
    let(:document_actions) { blacklight_config.show.document_actions }

    it "renders a document action" do
      allow(view).to receive(:some_action_solr_document_path).with(document, any_args).and_return 'x'
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new key: :some_action, name: :some_action, partial: 'document_action'
      render 'catalog/show_tools'
      expect(view).to have_received(:render).with(component)
    end

    context 'without any document actions defined' do
      before do
        document_actions.clear
      end

      it 'does not display the tools' do
        render 'catalog/show_tools'

        expect(rendered).to be_blank
      end
    end
  end
end
