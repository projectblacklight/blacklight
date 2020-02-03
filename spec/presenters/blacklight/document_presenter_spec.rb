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
    let(:field_config) { instance_double(Blacklight::Configuration::Field) }
    let(:options) { { a: 1 } }

    it 'calls the field presenter' do
      allow(Blacklight::FieldPresenter).to receive(:new).with(request_context, doc, field_config, options).and_return(field_presenter)
      expect(presenter.field_value(field_config, options)).to eq 'xyz'
    end
  end
end
