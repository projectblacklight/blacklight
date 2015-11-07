require 'spec_helper'

describe Blacklight::DeprecatedUrlHelperBehavior do
  around do |test|
    Deprecation.silence(described_class) do
      test.call
    end
  end
  
  let(:search_state) { Blacklight::SearchState.new(params, blacklight_config) }
  let(:params) { {} }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(helper).to receive(:search_state).and_return(search_state)
    allow(helper).to receive(:params).and_return(params)
    allow(helper).to receive(:blacklight_config).and_return(blacklight_config)
  end

  describe '#params_for_search' do
    it 'passes through to the search state' do
      expect(helper.params_for_search).to eq search_state.params_for_search
    end

    it 'passes arguments through to the search state' do
      expect(helper.params_for_search(merge: 1)).to eq search_state.params_for_search(merge: 1)
    end

    it 'generates a search state for the source parameters' do
      expect(helper.params_for_search({ source: 1 }, { merge: 1 })).to include merge: 1, source: 1
    end
  end

  describe '#sanitize_search_params' do
    it 'passes through to the parameter sanitizer' do
      expect(helper.sanitize_search_params(a: 1)).to eq Blacklight::Parameters.sanitize(a: 1)
    end
  end

  describe '#reset_search_params' do
    it 'resets the current page and counter' do
      expect(helper.reset_search_params(page: 1, counter: 10)).to be_blank
    end
  end

  describe '#add_facet_params' do
    before do
      blacklight_config.add_facet_field 'x'
    end

    let(:field) { blacklight_config.facet_fields['x'] }
    let(:item) { true }

    it 'passes through to the search state' do
      expect(helper.add_facet_params(field, item)).to eq search_state.add_facet_params(field, item)
    end

    it 'generates a search state for the source parameters' do
      expect(helper.add_facet_params(field, item, source: 1)).to include source: 1
    end
  end

  describe '#add_facet_params_and_redirect' do
    before do
      blacklight_config.add_facet_field 'x'
    end

    let(:field) { blacklight_config.facet_fields['x'] }
    let(:item) { true }

    it 'passes through to the search state' do
      expect(helper.add_facet_params_and_redirect(field, item)).to eq search_state.add_facet_params_and_redirect(field, item)
    end
  end

  describe '#remove_facet_params' do
    before do
      blacklight_config.add_facet_field 'x'
    end

    let(:field) { blacklight_config.facet_fields['x'] }
    let(:item) { true }

    it 'passes through to the search state' do
      expect(helper.remove_facet_params(field, item)).to eq search_state.remove_facet_params(field, item)
    end

    it 'generates a search state for the source parameters' do
      expect(helper.remove_facet_params(field, item, source: 1)).to include source: 1
    end
  end
end