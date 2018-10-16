# frozen_string_literal: true

describe Blacklight::IndexPresenter do
  include Capybara::RSpecMatchers
  let(:request_context) { double }
  let(:config) { Blacklight::Configuration.new }

  subject { presenter }
  let(:presenter) { described_class.new(document, request_context, config) }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:controller) { double }
  let(:search_state) { Blacklight::SearchState.new(params, config, controller) }

  let(:document) do
    SolrDocument.new(id: 1,
                     'link_to_search_true' => 'x',
                     'link_to_search_named' => 'x',
                     'qwer' => 'document qwer value')
  end

  before do
    allow(request_context).to receive(:search_state).and_return(search_state)
  end

  describe '#field_value' do
    subject { presenter.field_value field }

    let(:field) { config.index_fields[field_name] }
    let(:field_name) { 'asdf' }
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.add_index_field 'qwer'
        config.add_index_field 'asdf', helper_method: :render_asdf_index_field
        config.add_index_field 'link_to_search_true', link_to_search: true
        config.add_index_field 'link_to_search_named', link_to_search: :some_field
        config.add_index_field 'highlight', highlight: true
        config.add_index_field 'solr_doc_accessor', accessor: true
        config.add_index_field 'explicit_accessor', accessor: :solr_doc_accessor
        config.add_index_field 'alias', field: 'qwer'
        config.add_index_field 'with_default', default: 'value'
      end
    end

    context 'when a name is provided' do
      subject { presenter.field_value 'qwer' }

      it 'raises a deprecation' do
        expect(Deprecation).to receive(:warn)
        expect(subject).to eq 'document qwer value'
      end
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

    context 'when field has link_to_search with true' do
      before do
        allow(request_context).to receive(:search_action_path).with('f' => { 'link_to_search_true' => ['x'] }).and_return('/foo')
        allow(request_context).to receive(:link_to).with("x", '/foo').and_return('bar')
      end

      let(:field_name) { 'link_to_search_true' }

      it { is_expected.to eq 'bar' }
    end

    context 'when field has link_to_search with a field name' do
      before do
        allow(request_context).to receive(:search_action_path).with('f' => { 'some_field' => ['x'] }).and_return('/foo')
        allow(request_context).to receive(:link_to).with("x", '/foo').and_return('bar')
      end

      let(:field_name) { 'link_to_search_named' }

      it { is_expected.to eq 'bar' }
    end

    context 'when no highlight field is available' do
      before do
        allow(document).to receive(:has_highlight_field?).and_return(false)
      end

      let(:field_name) { 'highlight' }

      it { is_expected.to be_blank }
    end

    context 'when highlight field is available' do
      before do
        allow(document).to receive(:has_highlight_field?).and_return(true)
        allow(document).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
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
        allow(document).to receive_messages(solr_doc_accessor: "123")
      end

      let(:field_name) { 'solr_doc_accessor' }

      it { is_expected.to eq '123' }
    end

    context 'when accessor is set to a value' do
      let(:field_name) { 'explicit_accessor' }

      it 'calls the accessor with the field_name as the argument' do
        expect(document).to receive(:solr_doc_accessor).with('explicit_accessor').and_return("123")

        expect(subject).to eq '123'
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
      let(:field_config) { config.add_facet_field 'field_with_helper', helper_method: 'render_field_with_helper' }

      before do
        document['field_with_helper'] = 'value'
      end

      it "checks call the helper method with arguments" do
        allow(request_context).to receive(:render_field_with_helper) do |*args|
          args.first
        end

        render_options = { a: 1 }

        options = subject.send(:field_values, field_config, a: 1)

        expect(options).to include :document, :field, :value, :config, :a
        expect(options[:document]).to eq document
        expect(options[:field]).to eq 'field_with_helper'
        expect(options[:value]).to eq ['value']
        expect(options[:config]).to eq field_config
        expect(options[:a]).to eq 1
      end
    end
  end

  describe 'deprecated methods' do
    before do
      allow(Deprecation).to receive(:warn)
    end

    let(:field_config) { config.add_index_field 'qwerty' }

    describe '#get_field_values' do
      it 'renders values for the given field' do
        expect(subject.get_field_values(field_config, value: ['x', 'y'])).to eq 'x and y'
      end
    end

    describe '#render_field_values' do
      it 'renders values for the given field' do
        expect(subject.render_field_values('x')).to eq 'x'
      end
    end

    describe '#render_values' do
      it 'renders values for the given field' do
        expect(subject.render_values(['x', 'y', 'z'])).to eq 'x, y, and z'
      end
    end
  end
end
