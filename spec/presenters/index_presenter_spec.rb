# frozen_string_literal: true
require 'spec_helper'

describe Blacklight::IndexPresenter do
  include Capybara::RSpecMatchers
  let(:request_context) { double }
  let(:config) { Blacklight::Configuration.new }

  subject { presenter }
  let(:presenter) { described_class.new(document, request_context, config) }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:search_state) { Blacklight::SearchState.new(params, config) }

  let(:document) do
    SolrDocument.new(id: 1,
                     'link_to_search_true' => 'x',
                     'link_to_search_named' => 'x',
                     'qwer' => 'document qwer value',
                     'mnbv' => 'document mnbv value')
  end

  before do
    allow(request_context).to receive(:search_state).and_return(search_state)
  end

  describe "field_value" do
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.add_index_field 'qwer'
        config.add_index_field 'asdf', :helper_method => :render_asdf_index_field
        config.add_index_field 'link_to_search_true', :link_to_search => true
        config.add_index_field 'link_to_search_named', :link_to_search => :some_field
        config.add_index_field 'highlight', :highlight => true
        config.add_index_field 'solr_doc_accessor', :accessor => true
        config.add_index_field 'explicit_accessor', :accessor => :solr_doc_accessor
        config.add_index_field 'explicit_accessor_with_arg', :accessor => :solr_doc_accessor_with_arg
        config.add_index_field 'alias', field: 'qwer'
        config.add_index_field 'with_default', default: 'value'
      end
    end
    it "checks for an explicit value" do
      value = subject.field_value 'asdf', :value => 'asdf'
      expect(value).to eq 'asdf'
    end

    it "checks for a helper method to call" do
      allow(request_context).to receive(:render_asdf_index_field).and_return('custom asdf value')
      value = subject.field_value 'asdf'
      expect(value).to eq 'custom asdf value'
    end

    it "checks for a link_to_search" do
      allow(request_context).to receive(:search_action_path).with('f' => { 'link_to_search_true' => ['x'] }).and_return('/foo')
      allow(request_context).to receive(:link_to).with("x", '/foo').and_return('bar')
      value = subject.field_value 'link_to_search_true'
      expect(value).to eq 'bar'
    end

    it "checks for a link_to_search with a field name" do
      allow(request_context).to receive(:search_action_path).with('f' => { 'some_field' => ['x'] }).and_return('/foo')
      allow(request_context).to receive(:link_to).with("x", '/foo').and_return('bar')
      value = subject.field_value 'link_to_search_named'
      expect(value).to eq 'bar'
    end

    it "gracefully handles when no highlight field is available" do
      allow(document).to receive(:has_highlight_field?).and_return(false)
      value = subject.field_value 'highlight'
      expect(value).to be_blank
    end

    it "checks for a highlighted field" do
      allow(document).to receive(:has_highlight_field?).and_return(true)
      allow(document).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
      value = subject.field_value 'highlight'
      expect(value).to eq '<em>highlight</em>'
    end

    it "checks the document field value" do
      value = subject.field_value 'qwer'
      expect(value).to eq 'document qwer value'
    end

    it "should work with index fields that aren't explicitly defined" do
      value = subject.field_value 'mnbv'
      expect(value).to eq 'document mnbv value'
    end

    it "should call an accessor on the solr document" do
      allow(document).to receive_messages(solr_doc_accessor: "123")
      value = subject.field_value 'solr_doc_accessor'
      expect(value).to eq "123"
    end

    it "should call an explicit accessor on the solr document" do
      allow(document).to receive_messages(solr_doc_accessor: "123")
      value = subject.field_value 'explicit_accessor'
      expect(value).to eq "123"
    end

    it "should call an accessor on the solr document with the field as an argument" do
      allow(document).to receive(:solr_doc_accessor_with_arg).with('explicit_accessor_with_arg').and_return("123")
      value = subject.field_value 'explicit_accessor_with_arg'
      expect(value).to eq "123"
    end

    it "should support solr field configuration" do
      value = subject.field_value 'alias'
      expect(value).to eq "document qwer value"
    end

    it "should support default values in the field configuration" do
      value = subject.field_value 'with_default'
      expect(value).to eq "value"
    end
  end

  describe '#field_values' do
    context 'for a field with the helper_method option' do
      let(:field_name) { 'field_with_helper' }
      let(:field_config) { config.add_facet_field 'field_with_helper', helper_method: 'render_field_with_helper' }

      before do
        document['field_with_helper'] = 'value'
      end

      it "should check call the helper method with arguments" do
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
end

