# frozen_string_literal: true

RSpec.describe Blacklight::DocumentPresenter do
  subject(:presenter) { described_class.new(doc, request_context) }

  let(:doc) { instance_double(SolrDocument) }
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

    let(:field_config) { double(field: 'asdf') }

    context 'when all of the fields have values' do
      before do
        allow(presenter).to receive_messages(fields: { 'title' => field_config },
                                             render_field?: true,
                                             has_value?: true)
      end

      it { is_expected.to include(['title', field_config, an_instance_of(Blacklight::FieldPresenter)]) }
    end
  end

  describe '#render_field?' do
    subject { presenter.send(:render_field?, field_config) }

    let(:field_config) { double('field config', if: true, unless: false) }

    before do
      allow(presenter).to receive_messages(document_has_value?: true)
    end

    it { is_expected.to be true }

    context 'when the view context says not to render the field' do
      let(:request_context) { double('View context', should_render_field?: false, blacklight_config: blacklight_config) }

      before do
        allow(field_config).to receive_messages(if: false)
      end

      it { is_expected.to be false }
    end
  end

  describe '#has_value?' do
    subject { presenter.send(:has_value?, field_config) }

    context 'when the document has the field value' do
      let(:field_config) { double(field: 'asdf', highlight: false, accessor: nil, default: nil, values: nil) }

      before do
        allow(doc).to receive(:fetch).with('asdf', nil).and_return(['value'])
      end

      it { is_expected.to be true }
    end

    context 'when the document has a highlight field value' do
      let(:field_config) { double(field: 'asdf', highlight: true) }

      before do
        allow(doc).to receive(:has_highlight_field?).with('asdf').and_return(true)
        allow(doc).to receive(:highlight_field).with('asdf').and_return(['value'])
      end

      it { is_expected.to be true }
    end

    context 'when the field is a model accessor' do
      let(:field_config) { double(field: 'asdf', highlight: false, accessor: true) }

      before do
        allow(doc).to receive(:send).with('asdf').and_return(['value'])
      end

      it { is_expected.to be true }
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
