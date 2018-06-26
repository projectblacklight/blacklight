# frozen_string_literal: true

RSpec.describe "catalog/_show_tools.html.erb" do
  let(:document_model) { respond_to?(:solr_document_path) ? SolrDocument : ElasticsearchDocument }
  let(:document) { document_model.new id: 'xyz', format: 'a' }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:path) { respond_to?(:solr_document_path) ? :some_action_solr_document_path : :some_action_elasticsearch_documents_path }
  before do
    assign :response, instance_double(Blacklight::Solr::Response, params: {})
    assign :document, document
    allow(view).to receive(:blacklight_config).and_return blacklight_config
    allow(view).to receive(:has_user_authentication_provider?).and_return false
  end

  describe "document actions" do
    let(:document_actions) { blacklight_config.show.document_actions }

    it "renders a document action" do
      allow(view).to receive(:document_action_path).with(Blacklight::Configuration::ToolConfig, { id: document }).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).to have_link "Some action", href: "x"
    end

    it "uses the provided label" do
      allow(view).to receive(:document_action_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new label: "Some label", partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).to have_selector '.some_action', text: "Some label"
    end

    it "evaluates a document action's if configurations" do
      allow(view).to receive(:document_action_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new if: false, partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action', text: "Some action"
    end

    it "evaluates a document action's if configuration with a proc" do
      allow(view).to receive(:document_action_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', if: Proc.new { |config, doc| doc.id == "xyz" }
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action', text: "Some action"
    end

    it "evaluates a document action's unless configurations" do
      allow(view).to receive(:document_action_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', unless: true
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action', text: "Some action"
    end

    it "allows the tool to have a custom id" do
      allow(view).to receive(:document_action_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', id: "some_action"
      render partial: 'catalog/show_tools'
      expect(rendered).to have_selector '#some_action', text: "Some action"
    end

    it "defaults to modal behavior" do
      allow(view).to receive(:document_action_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).to have_selector '.some_action > a[data-blacklight-modal="trigger"]', text: "Some action"
    end

    it "allows configuration to opt out of modal behavior" do
      allow(view).to receive(:document_action_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', modal: false
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action > a[data-blacklight-modal="trigger"]', text: "Some action"
    end

    context 'without any document actions defined' do
      before do
        document_actions.clear
      end

      it 'does not display the tools' do
        render partial: 'catalog/show_tools'

        expect(rendered).to be_blank
      end
    end
  end
end
