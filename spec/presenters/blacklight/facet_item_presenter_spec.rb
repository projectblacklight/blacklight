# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::FacetItemPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_item, facet_config, view_context, search_state)
  end

  let(:facet_item) { instance_double(Blacklight::Solr::Response::Facets::FacetItem) }
  let(:filter_field) { instance_double(Blacklight::SearchState::FilterField, include?: true) }
  let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'key') }
  let(:view_context) { controller.view_context }
  let(:search_state) { instance_double(Blacklight::SearchState, filter: filter_field) }

  describe '#initialize' do
    before do
      allow(Blacklight.deprecation).to receive(:warn)
    end

    it 'defaults the search_state to the one from the view context' do
      allow(view_context).to receive(:search_state).and_return(search_state)
      expect(described_class.new(facet_item, facet_config, view_context).search_state).to eq search_state
      expect(Blacklight.deprecation).not_to have_received(:warn)
    end

    it 'accepts a search_state without a deprecation warning' do
      expect(presenter.search_state).to eq search_state
      expect(Blacklight.deprecation).not_to have_received(:warn)
    end

    it 'warns when passed the deprecated facet_field and a search_state' do
      presenter = described_class.new(facet_item, facet_config, view_context, 'key', search_state)
      expect(presenter.search_state).to eq search_state
      expect(Blacklight.deprecation).to have_received(:warn).with(/Passing facet_field/)
    end

    it 'warns when passed only the deprecated facet_field' do
      allow(view_context).to receive(:search_state).and_return(search_state)
      presenter = described_class.new(facet_item, facet_config, view_context, 'key')
      expect(presenter.search_state).to eq search_state
      expect(Blacklight.deprecation).to have_received(:warn).with(/Passing facet_field/)
    end

    it 'raises an error when given too many arguments' do
      expect { described_class.new(facet_item, facet_config, view_context, 'key', search_state, :extra) }.to raise_error ArgumentError
    end
  end

  describe '#selected?' do
    subject { presenter.selected? }

    it { is_expected.to be true }
  end

  describe '#label' do
    it "is the stringified facet value for an ordinary facet" do
      allow(facet_config).to receive_messages(query: nil, date: nil, helper_method: nil, url_method: nil)
      expect(presenter.label).to eq facet_item.to_s
    end

    it "allows you to pass in a :helper_method argument to the configuration" do
      allow(facet_config).to receive_messages(query: nil, date: nil, url_method: nil, helper_method: :my_facet_value_renderer)
      allow(view_context).to receive(:my_facet_value_renderer).with(facet_item).and_return('abc')
      expect(presenter.label).to eq 'abc'
    end

    context 'with a query facet' do
      let(:facet_item) { :query_key }

      it "extracts the configuration label for a query facet" do
        allow(facet_config).to receive_messages(query: { query_key: { label: 'XYZ' } }, date: nil, helper_method: nil, url_method: nil)
        expect(presenter.label).to eq 'XYZ'
      end
    end

    context 'with a date facet' do
      let(:facet_item) { '2012-01-01' }

      it "localizes the label for date-type facets" do
        allow(facet_config).to receive_messages('date' => true, :query => nil, :helper_method => nil, :url_method => nil)
        expect(presenter.label).to eq 'Sun, 01 Jan 2012 00:00:00 +0000'
      end

      it "localizes the label for date-type facets with the supplied localization options" do
        allow(facet_config).to receive_messages(date: { format: :short }, query: nil, helper_method: nil, url_method: nil)
        expect(presenter.label).to eq '01 Jan 00:00'
      end
    end
  end

  describe '#href' do
    let(:filter_field) { instance_double(Blacklight::SearchState::FilterField, include?: false) }

    it 'is the url to apply the facet' do
      allow(search_state).to receive(:add_facet_params_and_redirect).with('key', facet_item).and_return(f: 'x')
      allow(view_context).to receive(:search_action_path).with({ f: 'x' }).and_return('/catalog?f=x')

      expect(presenter.href).to eq '/catalog?f=x'
    end

    context 'with url_method configuration' do
      before do
        allow(facet_config).to receive_messages(url_method: :some_helper_method)
      end

      it 'calls out to a helper to determine the url' do
        allow(view_context).to receive(:some_helper_method).and_return('/xyz').with('key', facet_item)

        expect(presenter.href).to eq '/xyz'
      end
    end

    context 'with a selected facet' do
      let(:filter_field) { instance_double(Blacklight::SearchState::FilterField, include?: true, remove: {}) }

      before do
        allow(view_context).to receive(:search_action_path).with({}).and_return('/catalog')
      end

      it 'is the url to remove the facet' do
        expect(presenter.href).to eq '/catalog'
      end
    end
  end
end
