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
    subject { presenter.fields_to_render }

    let(:field_config) { double(field: 'asdf') }

    context 'when all of the fields have values' do
      before do
        allow(presenter).to receive_messages(fields: { 'title' => field_config },
                                             render_field?: true,
                                             has_value?: true)
      end

      it { is_expected.to eq('title' => field_config) }
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
    subject { presenter.field_value field }

    let(:doc) do
      SolrDocument.new(id: 1,
                       'link_to_facet_true' => 'x',
                       'link_to_facet_named' => 'x',
                       'qwer' => 'document qwer value')
    end

    let(:field) { config.index_fields[field_name] }
    let(:field_name) { 'asdf' }
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.add_index_field 'qwer'
        config.add_index_field 'asdf', helper_method: :render_asdf_index_field
        config.add_index_field 'link_to_facet_true', link_to_facet: true
        config.add_index_field 'link_to_facet_named', link_to_facet: :some_field
        config.add_index_field 'highlight', highlight: true
        config.add_index_field 'solr_doc_accessor', accessor: true
        config.add_index_field 'explicit_accessor', accessor: :solr_doc_accessor
        config.add_index_field 'explicit_array_accessor', accessor: [:solr_doc_accessor, :some_method]
        config.add_index_field 'explicit_values', values: ->(_config, _doc) { ['some-value'] }
        config.add_index_field 'alias', field: 'qwer'
        config.add_index_field 'with_default', default: 'value'
      end
    end

    context 'when an explicit html value is provided' do
      subject { presenter.field_value field, value: '<b>val1</b>' }

      it { is_expected.to eq '&lt;b&gt;val1&lt;/b&gt;' }
    end

    context 'when an explicit array value with unsafe characters is provided' do
      subject { presenter.field_value field, value: ['<a', 'b'] }

      it { is_expected.to eq '&lt;a and b' }
    end

    context 'when an explicit array value is provided' do
      subject { presenter.field_value field, value: %w[a b c] }

      it { is_expected.to eq 'a, b, and c' }
    end

    context 'when an explicit value is provided' do
      subject { presenter.field_value field, value: 'asdf' }

      it { is_expected.to eq 'asdf' }
    end

    context 'when field has a helper method' do
      before do
        allow(request_context).to receive(:render_asdf_index_field).and_return('custom asdf value')
      end

      it { is_expected.to eq 'custom asdf value' }
    end

    context 'when field has link_to_facet with true' do
      before do
        allow(request_context).to receive(:search_action_path).with('f' => { 'link_to_facet_true' => ['x'] }).and_return('/foo')
        allow(request_context).to receive(:link_to).with("x", '/foo').and_return('bar')
      end

      let(:field_name) { 'link_to_facet_true' }

      it { is_expected.to eq 'bar' }
    end

    context 'when field has link_to_facet with a field name' do
      before do
        allow(request_context).to receive(:search_action_path).with('f' => { 'some_field' => ['x'] }).and_return('/foo')
        allow(request_context).to receive(:link_to).with("x", '/foo').and_return('bar')
      end

      let(:field_name) { 'link_to_facet_named' }

      it { is_expected.to eq 'bar' }
    end

    context 'when no highlight field is available' do
      before do
        allow(doc).to receive(:has_highlight_field?).and_return(false)
      end

      let(:field_name) { 'highlight' }

      it { is_expected.to be_blank }
    end

    context 'when highlight field is available' do
      before do
        allow(doc).to receive(:has_highlight_field?).and_return(true)
        allow(doc).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      end

      let(:field_name) { 'highlight' }

      it { is_expected.to eq '<em>highlight</em>' }
    end

    context 'when no options are provided' do
      let(:field_name) { 'qwer' }

      it "checks the document field value" do
        expect(subject).to eq 'document qwer value'
      end
    end

    context 'when accessor is true' do
      before do
        allow(doc).to receive_messages(solr_doc_accessor: "123")
      end

      let(:field_name) { 'solr_doc_accessor' }

      it { is_expected.to eq '123' }
    end

    context 'when accessor is set to a value' do
      let(:field_name) { 'explicit_accessor' }

      it 'calls the accessor with the field_name as the argument' do
        expect(doc).to receive(:solr_doc_accessor).with('explicit_accessor').and_return("123")

        expect(subject).to eq '123'
      end
    end

    context 'when accessor is set to an array' do
      let(:field_name) { 'explicit_array_accessor' }

      it 'calls the accessors on the return of the preceeding' do
        allow(doc).to receive_message_chain(:solr_doc_accessor, some_method: "123")

        expect(subject).to eq '123'
      end
    end

    context 'when the values lambda is provided' do
      let(:field_name) { 'explicit_values' }

      it 'calls the accessors on the return of the preceeding' do
        expect(subject).to eq 'some-value'
      end
    end

    context 'when the field is an alias' do
      let(:field_name) { 'alias' }

      it { is_expected.to eq 'document qwer value' }
    end

    context 'when the field has a default' do
      let(:field_name) { 'with_default' }

      it { is_expected.to eq 'value' }
    end
  end

  describe '#field_values' do
    context 'for a field with the helper_method option' do
      let(:field_name) { 'field_with_helper' }
      let(:field_config) { blacklight_config.add_facet_field 'field_with_helper', helper_method: 'render_field_with_helper' }
      let(:doc) do
        SolrDocument.new(id: 1, 'field_with_helper' => 'value')
      end

      it "checks call the helper method with arguments" do
        allow(request_context).to receive(:render_field_with_helper) do |*args|
          args.first
        end

        options = subject.send(:field_values, field_config, a: 1)

        expect(options).to include :document, :field, :value, :config, :a
        expect(options[:document]).to eq doc
        expect(options[:field]).to eq 'field_with_helper'
        expect(options[:value]).to eq ['value']
        expect(options[:config]).to eq field_config
        expect(options[:a]).to eq 1
      end
    end
  end

end
