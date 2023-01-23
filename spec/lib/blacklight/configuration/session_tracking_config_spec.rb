# frozen_string_literal: true

RSpec.describe Blacklight::Configuration::SessionTrackingConfig do
  subject(:config) { described_class.new }

  it "defaults @storage to 'server'" do
    expect(config.storage).to eq 'server'
  end

  context "@storage is set to 'server'" do
    before do
      config.storage = 'server'
    end

    it "defaults components values" do
      expect(config.applied_params_component).to eq Blacklight::SearchContext::ServerAppliedParamsComponent
    end
  end

  context "@storage is set to 'client'" do
    before do
      config.storage = 'client'
    end

    it "defaults components values" do
      expect(config.applied_params_component).to eq Blacklight::SearchContext::ClientAppliedParamsComponent
    end
  end

  context "@storage is set to false" do
    before do
      config.storage = false
    end

    it "defaults components values" do
      expect(config.applied_params_component).to be_nil
    end
  end
end
