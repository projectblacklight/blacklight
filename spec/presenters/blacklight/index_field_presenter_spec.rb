# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::IndexFieldPresenter do
  let(:view_context) { double(search_state: search_state) }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:search_state) { Blacklight::SearchState.new(params, config) }
  let(:index_presenter) { instance_double(Blacklight::IndexPresenter,
                                          view_context: view_context,
                                          document: document) }
  let(:instance) { Blacklight::IndexFieldPresenter.new(index_presenter, field) }
  let(:field) { double }

  let(:document) do
    SolrDocument.new(id: 1,
                     'link_to_facet_true' => 'x',
                     'link_to_facet_named' => 'x',
                     'qwer' => 'document qwer value',
                     'mnbv' => 'document mnbv value')
  end

  describe "#value" do
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.add_index_field 'qwer'
        config.add_index_field 'asdf', :helper_method => :render_asdf_index_field
        config.add_index_field 'link_to_facet_true', :link_to_facet => true
        config.add_index_field 'link_to_facet_named', :link_to_facet => :some_field
        config.add_index_field 'highlight', :highlight => true
        config.add_index_field 'solr_doc_accessor', :accessor => true
        config.add_index_field 'explicit_accessor', :accessor => :solr_doc_accessor
        config.add_index_field 'explicit_accessor_with_arg', :accessor => :solr_doc_accessor_with_arg
        config.add_index_field 'alias', field: 'qwer'
        config.add_index_field 'with_default', default: 'value'
      end
    end

    context "with an explicit value" do
      subject { instance.value(value: 'asdf') }
      let(:field) { config.index_fields['asdf'] }
      it "checks for an explicit value" do
        expect(subject).to eq 'asdf'
      end
    end

    subject { instance.value }

    context "with a helper method call" do
      let(:field) { config.index_fields['asdf'] }
      it "checks for a helper method to call" do
        allow(view_context).to receive(:render_asdf_index_field).and_return('custom asdf value')
        expect(subject).to eq 'custom asdf value'
      end
    end

    context "with a field that links to facet" do
      let(:field) { config.index_fields['link_to_facet_true'] }

      it "checks for a link_to_facet" do
        allow(view_context).to receive(:search_action_path).with('f' => { 'link_to_facet_true' => ['x'] }).and_return('/foo')
        allow(view_context).to receive(:link_to).with("x", '/foo').and_return('bar')
        expect(subject).to eq 'bar'
      end
    end

    context "with a named link to facet" do
      let(:field) { config.index_fields['link_to_facet_named'] }
      it "checks for a link_to_facet with a field name" do
        allow(view_context).to receive(:search_action_path).with('f' => { 'some_field' => ['x'] }).and_return('/foo')
        allow(view_context).to receive(:link_to).with("x", '/foo').and_return('bar')
        expect(subject).to eq 'bar'
      end
    end

    context "when no highlight field is available" do
      let(:field) { config.index_fields['highlight'] }
      it "is blank" do
        allow(document).to receive(:has_highlight_field?).and_return(false)
        expect(subject).to be_blank
      end
    end

    context "when a highlight field is available" do
      let(:field) { config.index_fields['highlight'] }
      it "checks for a highlighted field" do
        allow(document).to receive(:has_highlight_field?).and_return(true)
        allow(document).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
        expect(subject).to eq '<em>highlight</em>'
      end
    end

    context "with a regular value" do
      let(:field) { config.index_fields['qwer'] }
      it "checks the document field value" do
        expect(subject).to eq 'document qwer value'
      end
    end

    context "with an accessor on the solr document" do
      let(:field) { config.index_fields['solr_doc_accessor'] }
      it "calls the accessor method" do
        allow(document).to receive_messages(solr_doc_accessor: "123")
        expect(subject).to eq "123"
      end
    end

    context "with an explicit accessor on the solr document" do
      let(:field) { config.index_fields['explicit_accessor'] }
      it "calls the accessor method" do
        allow(document).to receive_messages(solr_doc_accessor: "123")
        expect(subject).to eq "123"
      end
    end

    context "with an explicit accessor that takes an argument" do
      let(:field) { config.index_fields['explicit_accessor_with_arg'] }
      it "calls an accessor on the solr document with the field as an argument" do
        allow(document).to receive(:solr_doc_accessor_with_arg).with('explicit_accessor_with_arg').and_return("123")
        expect(subject).to eq "123"
      end
    end

    context "with solr field configuration" do
      let(:field) { config.index_fields['alias'] }
      it "is successful" do
        expect(subject).to eq "document qwer value"
      end
    end

    context "with default values" do
      let(:field) { config.index_fields['with_default'] }
      it "returns the default value" do
        expect(subject).to eq "value"
      end
    end

    context 'for a field with the helper_method option' do
      let(:field_name) { 'field_with_helper' }
      let(:config) do
        Blacklight::Configuration.new
      end
      let(:field) { config.add_facet_field 'field_with_helper', helper_method: 'render_field_with_helper' }
      let(:document) do
        SolrDocument.new(id: 1, 'field_with_helper' => 'value')
      end

      it "checks call the helper method with arguments" do
        allow(view_context).to receive(:render_field_with_helper) do |*args|
          args.first
        end

        render_options = { a: 1 }

        options = instance.send(:value, a: 1)

        expect(options).to include :document, :field, :value, :config, :a
        expect(options[:document]).to eq document
        expect(options[:field]).to eq 'field_with_helper'
        expect(options[:value]).to eq ['value']
        expect(options[:config]).to eq field
        expect(options[:a]).to eq 1
      end
    end
  end
end
