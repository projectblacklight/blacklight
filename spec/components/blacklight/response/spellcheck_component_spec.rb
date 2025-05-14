# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::Response::SpellcheckComponent, type: :component do
  subject(:render) { render_inline(instance) }

  let(:spellcheck_options) { nil }
  let(:instance) { described_class.new(response: response, options: spellcheck_options) }
  let(:config) do
    Blacklight::Configuration.new do |config|
      config.spell_max = 5
    end
  end

  before do
    allow(vc_test_controller).to receive(:blacklight_config).and_return(config)
  end

  context 'when there are many results' do
    let(:response) { instance_double(Blacklight::Solr::Response, total: 10, spelling: double(words: [1], collation: nil)) }

    it "does not show suggestions" do
      expect(render.to_html).to be_blank
    end
  end

  context 'when there are only a few results' do
    let(:word_suggestion) { 'yoshida' }
    let(:response) { instance_double(Blacklight::Solr::Response, total: 4, spelling: double(words: [word_suggestion], collation: nil)) }

    it "shows suggestions" do
      expect(render.to_html).to include(word_suggestion)
    end

    context 'and explicit spellcheck options' do
      let(:explicit_option) { 'explicit option' }
      let(:spellcheck_options) { [explicit_option] }

      it "shows only explicit suggestions" do
        expect(render.to_html).to include(explicit_option)
        expect(render.to_html).not_to include(word_suggestion)
      end
    end

    context 'and collations are present' do
      let(:word_suggestion) { 'donotuse' }
      let(:collated_suggestion) { 'yoshida Hajime' }
      let(:response) { instance_double(Blacklight::Solr::Response, total: 4, spelling: double(words: [word_suggestion], collation: collated_suggestion)) }

      it "shows only collated suggestions" do
        expect(render.to_html).to include(collated_suggestion)
        expect(render.to_html).not_to include(word_suggestion)
      end
    end
  end

  context 'when there are no spelling suggestions' do
    let(:response) { instance_double(Blacklight::Solr::Response, total: 4, spelling: double(words: [], collation: nil)) }

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
