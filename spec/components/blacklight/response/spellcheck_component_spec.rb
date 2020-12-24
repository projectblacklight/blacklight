# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::SpellcheckComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:instance) { described_class.new(response: response) }
  let(:config) do
    Blacklight::Configuration.new do |config|
      config.spell_max = 5
    end
  end

  before do
    allow(controller).to receive(:blacklight_config).and_return(config)
  end

  context 'when there are many results' do
    let(:response) { instance_double(Blacklight::Solr::Response, total: 10, spelling: double(words: [1])) }

    it "does not show suggestions" do
      expect(render.to_html).to be_blank
    end
  end

  context 'when there are only a few results' do
    let(:response) { instance_double(Blacklight::Solr::Response, total: 4, spelling: double(words: [1])) }

    it "shows suggestions" do
      expect(render.to_html).not_to be_blank
    end
  end

  context 'when there are no spelling suggestions' do
    let(:response) { instance_double(Blacklight::Solr::Response, total: 4, spelling: double(words: [])) }

    it "does not show suggestions" do
      expect(render.to_html).to be_blank
    end
  end

  context 'when spelling is not available' do
    let(:response) { instance_double(Blacklight::Solr::Response, total: 4, spelling: nil) }

    it "does not show suggestions" do
      expect(render.to_html).to be_blank
    end
  end
end
