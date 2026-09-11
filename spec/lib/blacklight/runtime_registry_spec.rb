# frozen_string_literal: true

RSpec.describe Blacklight::RuntimeRegistry do
  before { described_class.stats.reset }

  describe ".call" do
    it "accumulates the event's duration into stats.solr_runtime" do
      described_class.call("solr_request.blacklight", 0.0, 0.0125, nil, {})

      expect(described_class.stats.solr_runtime).to eq 12.5
    end

    it "increments stats.solr_query_count" do
      described_class.call("solr_request.blacklight", 0.0, 0.0125, nil, {})
      described_class.call("solr_request.blacklight", 0.0, 0.0125, nil, {})

      expect(described_class.stats.solr_query_count).to eq 2
    end
  end

  describe ".stats" do
    it "is thread-local" do
      described_class.call("solr_request.blacklight", 0.0, 0.0125, nil, {})

      Thread.new { expect(described_class.stats.solr_runtime).to eq 0.0 }.join
    end
  end

  describe "Stats#reset" do
    it "clears the accumulated runtime and query count" do
      stats = described_class.stats
      described_class.call("solr_request.blacklight", 0.0, 0.0125, nil, {})

      stats.reset

      expect(stats.solr_runtime).to eq 0.0
      expect(stats.solr_query_count).to eq 0
    end
  end

  describe "subscribed to solr_request.blacklight notifications" do
    it "fires without raising (Blacklight::Engine subscribes this at boot)" do
      expect { ActiveSupport::Notifications.instrument("solr_request.blacklight") }.not_to raise_error
    end
  end
end
