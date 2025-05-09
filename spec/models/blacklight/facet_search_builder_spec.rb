# frozen_string_literal: true

RSpec.describe Blacklight::FacetSearchBuilder, :api do
  subject(:builder) { described_class.new processor_chain, scope }

  let(:processor_chain) { [] }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:scope) { double blacklight_config: blacklight_config, search_state_class: nil }

  describe "#facet_suggestion_query" do
    it "is nil if no value is set" do
      expect(subject.facet_suggestion_query).to be_nil
    end

    it "sets facet_suggestion_query value" do
      expect(subject.facet_suggestion_query('antel').facet_suggestion_query).to eq 'antel'
    end
  end
end
