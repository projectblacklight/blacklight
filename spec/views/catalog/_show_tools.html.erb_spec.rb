require 'spec_helper'

describe "catalog/_show_tools.html.erb" do
  let :document do
    SolrDocument.new :id => 'xyz', :format => 'a'
  end

  let :blacklight_config do
    Blacklight::Configuration.new
  end

  before do
    assign :response, double(:params => {})
    assign :document, document
    allow(view).to receive(:blacklight_config).and_return blacklight_config
    allow(view).to receive(:has_user_authentication_provider?).and_return false
  end

  describe "document actions" do

    let :document_actions do
      blacklight_config.show.document_actions
    end


    it "should render a document action" do
      allow(view).to receive(:some_action_solr_document_path).with(document).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).to have_link "Some action", href: "x"
    end

    it "should use the provided label" do
      allow(view).to receive(:some_action_solr_document_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new label: "Some label", partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).to have_selector '.some_action', text: "Some label"
    end

    it "should evaluate a document action's if configurations" do
      allow(view).to receive(:some_action_solr_document_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new if: false, partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action', text: "Some action"
    end

    it "should evaluate a document action's if configuration with a proc" do
      allow(view).to receive(:some_action_solr_document_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', if: Proc.new { |config, doc| doc.id == "xyz" }
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action', text: "Some action"
    end

    it "should evaluate a document action's unless configurations" do
      allow(view).to receive(:some_action_solr_document_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', unless: true
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action', text: "Some action"
    end

    it "should allow the tool to have a custom id" do
      allow(view).to receive(:some_action_solr_document_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', id: "some_action"
      render partial: 'catalog/show_tools'
      expect(rendered).to have_selector '#some_action', text: "Some action"
    end

    it "should default to modal behavior" do
      allow(view).to receive(:some_action_solr_document_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action'
      render partial: 'catalog/show_tools'
      expect(rendered).to have_selector '.some_action > a[data-ajax-modal="trigger"]', text: "Some action"
    end

    it "should allow configuration to opt out of modal behavior" do
      allow(view).to receive(:some_action_solr_document_path).and_return "x"
      document_actions[:some_action] = Blacklight::Configuration::ToolConfig.new partial: 'document_action', modal: false
      render partial: 'catalog/show_tools'
      expect(rendered).not_to have_selector '.some_action > a[data-ajax-modal="trigger"]', text: "Some action"
    end
  end
end
