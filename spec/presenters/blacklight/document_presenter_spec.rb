# frozen_string_literal: true

RSpec.describe Blacklight::DocumentPresenter do
  subject(:presenter) { described_class.new(doc, request_context) }

  let(:doc) { SolrDocument.new('asdf' => 'asdf') }
  let(:blacklight_config) { Blacklight::Configuration.new }
  let(:request_context) { double('View context', should_render_field?: true, blacklight_config: blacklight_config) }
  let(:controller) { double }
  let(:params) { {} }
  let(:search_state) { Blacklight::SearchState.new(params, blacklight_config, controller) }

  before do
    allow(request_context).to receive(:search_state).and_return(search_state)
  end

  describe '#fields_to_render' do
    subject { presenter.fields_to_render.to_a }

    let(:field_config) { Blacklight::Configuration::Field.new(field: 'asdf') }

    context 'when all of the fields have values' do
      before do
        allow(presenter).to receive_messages(fields: { 'title' => field_config })
      end

      it { is_expected.to include(['title', field_config, an_instance_of(Blacklight::FieldPresenter)]) }
    end
  end

  describe '#field_value' do
    let(:field_presenter) { instance_double(Blacklight::FieldPresenter, render: 'xyz') }
    let(:field_config) { Blacklight::Configuration::Field.new }
    let(:options) { { a: 1 } }

    it 'calls the field presenter' do
      allow(Blacklight::FieldPresenter).to receive(:new).with(request_context, doc, field_config, options).and_return(field_presenter)
      expect(presenter.field_value(field_config, options)).to eq 'xyz'
    end

    it 'can be configured to use an alternate presenter' do
      instance = double(render: 'abc')
      stub_const('SomePresenter', Class.new)
      field_config.presenter = SomePresenter
      allow(SomePresenter).to receive(:new).and_return(instance)

      expect(presenter.field_value(field_config, options)).to eq 'abc'
    end
  end

  describe '#thumbnail' do
    it 'returns a thumbnail presenter' do
      expect(presenter.thumbnail).to be_a_kind_of(Blacklight::ThumbnailPresenter)
    end

    it 'use the configured thumbnail presenter' do
      custom_presenter_class = Class.new(Blacklight::ThumbnailPresenter)
      blacklight_config.index.thumbnail_presenter = custom_presenter_class

      expect(presenter.thumbnail).to be_a_kind_of custom_presenter_class
    end
  end
end
