# frozen_string_literal: true

RSpec.describe ApplicationController do
  describe ".log_process_action" do
    it "appends Solr runtime to the messages ActiveRecord/ActionController already log" do
      messages = described_class.log_process_action(solr_runtime: 45.3, solr_query_count: 2)
      expect(messages).to include("Solr: 45.3ms (2 queries)")
    end

    it "uses singular 'query' for a single Solr request" do
      messages = described_class.log_process_action(solr_runtime: 12.0, solr_query_count: 1)
      expect(messages).to include("Solr: 12.0ms (1 query)")
    end

    it "does not add a message when no Solr request was made" do
      messages = described_class.log_process_action({})
      expect(messages.grep(/Solr/)).to be_empty
    end

    it "does not add a message when the payload reports zero Solr queries" do
      # Stats#solr_runtime defaults to 0.0 (truthy, never nil) - query count is the real "did Solr get queried" signal.
      messages = described_class.log_process_action(solr_runtime: 0.0, solr_query_count: 0)
      expect(messages.grep(/Solr/)).to be_empty
    end
  end

  describe "#blacklight_config" do
    it "provides a default blacklight_config everywhere" do
      expect(controller.blacklight_config).to eq CatalogController.blacklight_config
    end
  end
end
