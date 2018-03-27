# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Blacklight::ShowFieldPresenter do
  let(:view_context) { double(search_state: search_state) }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:search_state) { Blacklight::SearchState.new(params, config) }
  let(:index_presenter) { instance_double(Blacklight::ShowPresenter,
                                          view_context: view_context,
                                          document: document) }
  let(:instance) { described_class.new(index_presenter, field) }
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
        config.add_show_field 'qwer'
        config.add_show_field 'asdf', :helper_method => :render_asdf_document_show_field
        config.add_show_field 'link_to_facet_true', :link_to_facet => true
        config.add_show_field 'link_to_facet_named', :link_to_facet => :some_field
        config.add_show_field 'highlight', :highlight => true
        config.add_show_field 'solr_doc_accessor', :accessor => true
        config.add_show_field 'explicit_accessor', :accessor => :solr_doc_accessor
        config.add_show_field 'explicit_array_accessor', :accessor => [:solr_doc_accessor, :some_method]
        config.add_show_field 'explicit_accessor_with_arg', :accessor => :solr_doc_accessor_with_arg
      end
    end

    subject { instance.value }

    context "with an html value" do
      subject { instance.value(value: '<b>val1</b>') }
      let(:field) { config.show_fields['asdf'] }
      it 'html-escapes values' do
        expect(subject).to eq '&lt;b&gt;val1&lt;/b&gt;'
      end
    end

    context "with two values parameters" do
      subject { instance.value(value: ['<a', 'b']) }
      let(:field) { config.show_fields['asdf'] }
      it 'joins multivalued valued fields' do
        expect(subject).to eq '&lt;a and b'
      end
    end

    context "with three values parameters" do
      subject { instance.value(value: ['a', 'b', 'c']) }
      let(:field) { config.show_fields['asdf'] }
      it 'joins multivalued valued fields' do
        expect(subject).to eq 'a, b, and c'
      end
    end

    context "with an explicit value" do
      subject { instance.value(value: 'val1') }
      let(:field) { config.show_fields['asdf'] }
      it "doesn't call the helper" do
        expect(view_context).to_not receive(:render_asdf_document_show_field)
        expect(subject).to eq 'val1'
      end
    end

    context "with a helper method" do
      let(:field) { config.show_fields['asdf'] }
      it "checks for a helper method to call" do
        allow(view_context).to receive(:render_asdf_document_show_field).and_return('custom asdf value')
        expect(subject).to eq 'custom asdf value'
      end
    end

    context "with a link_to_facet" do
      let(:field) { config.show_fields['link_to_facet_true'] }
      it "checks for a link_to_facet" do
        allow(view_context).to receive(:search_action_path).and_return('/foo')
        allow(view_context).to receive(:link_to).with("x", '/foo').and_return('bar')
        expect(subject).to eq 'bar'
      end
    end

    context "with a link_to_facet with a field name" do
      let(:field) { config.show_fields['link_to_facet_named'] }
      it "checks for a link_to_facet with a field name" do
        allow(view_context).to receive(:search_action_path).and_return('/foo')
        allow(view_context).to receive(:link_to).with("x", '/foo').and_return('bar')
        expect(subject).to eq 'bar'
      end
    end

    context "when no highlight field is available" do
      before do
        allow(document).to receive(:has_highlight_field?).and_return(false)
      end
      let(:field) { config.show_fields['highlight'] }
      it "is blank" do
        expect(subject).to be_blank
      end
    end

    context "with a highlighted field" do
      let(:field) { config.show_fields['highlight'] }
      it "checks for a highlighted field" do
        allow(document).to receive(:has_highlight_field?).and_return(true)
        allow(document).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe])
        expect(subject).to eq '<em>highlight</em>'
      end
    end

    context "with a highlighted field" do
      let(:field) { config.show_fields['highlight'] }
      it 'respects the HTML-safeness of multivalued highlight fields' do
        allow(document).to receive(:has_highlight_field?).and_return(true)
        allow(document).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe, '<em>other highlight</em>'.html_safe])
        expect(subject).to eq '<em>highlight</em> and <em>other highlight</em>'
      end
    end

    context "with a regular field" do
      let(:field) { config.show_fields['qwer'] }
      it "checks the document field value" do
        expect(subject).to eq 'document qwer value'
      end
    end

    context "with an accessor on the solr document" do
      let(:field) { config.show_fields['solr_doc_accessor'] }
      it "calls the accessor method" do
        allow(document).to receive_messages(solr_doc_accessor: "123")
        expect(subject).to eq "123"
      end
    end

    context "with an explicit accessor on the solr document" do
      let(:field) { config.show_fields['explicit_accessor'] }
      it "calls the accessor method" do
        allow(document).to receive_messages(solr_doc_accessor: "123")
        expect(subject).to eq "123"
      end
    end


    context "with an explicit array style accessor on the solr document" do
      let(:field) { config.show_fields['explicit_array_accessor'] }
      it "calls an explicit array-style accessor on the solr document" do
        allow(document).to receive_message_chain(:solr_doc_accessor, some_method: "123")
        expect(subject).to eq "123"
      end
    end

    context "with an explicit accessor on the solr document with an argument" do
      let(:field) { config.show_fields['explicit_accessor_with_arg'] }
      it "calls an accessor on the solr document with the field as an argument" do
        allow(document).to receive(:solr_doc_accessor_with_arg).with('explicit_accessor_with_arg').and_return("123")
        expect(subject).to eq "123"
      end
    end

    context 'for a field with the helper_method option' do
      let(:config) do
        Blacklight::Configuration.new
      end
      let(:field) { config.add_facet_field 'field_with_helper', helper_method: 'render_field_with_helper' }
      let(:document) do
        SolrDocument.new(id: 1, 'field_with_helper' => 'value')
      end

      subject { instance.value(a: 1) }

      it "checks call the helper method with arguments" do
        allow(view_context).to receive(:render_field_with_helper) do |*args|
          args.first
        end

        expect(subject).to include :document, :field, :value, :config, :a
        expect(subject[:document]).to eq document
        expect(subject[:field]).to eq 'field_with_helper'
        expect(subject[:value]).to eq ['value']
        expect(subject[:config]).to eq field
        expect(subject[:a]).to eq 1
      end
    end
  end
end
