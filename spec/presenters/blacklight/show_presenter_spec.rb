# frozen_string_literal: true

RSpec.describe Blacklight::ShowPresenter do
  include Capybara::RSpecMatchers
  subject { presenter }

  let(:request_context) { double }
  let(:config) { Blacklight::Configuration.new }

  let(:presenter) { described_class.new(document, request_context, config) }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:controller) { double }
  let(:search_state) { Blacklight::SearchState.new(params, config, controller) }

  let(:document) do
    SolrDocument.new(id: 1,
                     'link_to_facet_true' => 'x',
                     'link_to_facet_named' => 'x',
                     'qwer' => 'document qwer value')
  end

  before do
    allow(request_context).to receive(:search_state).and_return(search_state)
  end

  describe "link_rel_alternates" do
    before do
      class MockDocument
        include Blacklight::Solr::Document
      end

      module MockExtension
        def self.extended(document)
          document.will_export_as(:weird, "application/weird")
          document.will_export_as(:weirder, "application/weirder")
          document.will_export_as(:weird_dup, "application/weird")
        end

        def export_as_weird
          "weird"
        end

        def export_as_weirder
          "weirder"
        end

        def export_as_weird_dup
          "weird_dup"
        end
      end

      MockDocument.use_extension(MockExtension)

      def mock_document_app_helper_url *args
        solr_document_url(*args)
      end

      allow(request_context).to receive(:polymorphic_url) do |_, opts|
        "url.#{opts[:format]}"
      end
    end

    let(:document) { MockDocument.new(id: "MOCK_ID1") }

    context "with no arguments" do
      subject { presenter.link_rel_alternates }

      it "generates <link rel=alternate> tags" do
        tmp_value = Capybara.ignore_hidden_elements
        Capybara.ignore_hidden_elements = false
        document.export_formats.each_pair do |format, _spec|
          expect(subject).to have_selector("link[href$='.#{format}']") do |matches|
            expect(matches).to have(1).match
            tag = matches[0]
            expect(tag.attributes["rel"].value).to eq "alternate"
            expect(tag.attributes["title"].value).to eq format.to_s
            expect(tag.attributes["href"].value).to eq mock_document_app_helper_url(document, format: format)
          end
        end
        Capybara.ignore_hidden_elements = tmp_value
      end

      it { is_expected.to be_html_safe }
    end

    context "with unique: true" do
      subject { presenter.link_rel_alternates(unique: true) }

      it "respects unique: true" do
        tmp_value = Capybara.ignore_hidden_elements
        Capybara.ignore_hidden_elements = false
        expect(subject).to have_selector("link[type='application/weird']", count: 1)
        Capybara.ignore_hidden_elements = tmp_value
      end
    end

    context "with exclude" do
      subject { presenter.link_rel_alternates(unique: true) }

      it "excludes formats from :exclude" do
        tmp_value = Capybara.ignore_hidden_elements
        Capybara.ignore_hidden_elements = false
        expect(subject).not_to have_selector("link[href$='.weird_dup']")
        Capybara.ignore_hidden_elements = tmp_value
      end
    end
  end

  describe '#field_value' do
    subject { presenter.field_value field }

    let(:field) { config.show_fields[field_name] }
    let(:field_name) { 'asdf' }
    let(:config) do
      Blacklight::Configuration.new.configure do |config|
        config.add_show_field 'qwer'
        config.add_show_field 'asdf', helper_method: :render_asdf_document_show_field
        config.add_show_field 'link_to_facet_true', link_to_facet: true
        config.add_show_field 'link_to_facet_named', link_to_facet: :some_field
        config.add_show_field 'highlight', highlight: true
        config.add_show_field 'solr_doc_accessor', accessor: true
        config.add_show_field 'explicit_accessor', accessor: :solr_doc_accessor
        config.add_show_field 'explicit_array_accessor', accessor: [:solr_doc_accessor, :some_method]
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
      subject { presenter.field_value field, value: 'val1' }

      it { is_expected.to eq 'val1' }
    end

    context 'when field has a helper method' do
      before do
        allow(request_context).to receive(:render_asdf_document_show_field).and_return('custom asdf value')
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

    context 'when highlight returns multiple values' do
      before do
        allow(document).to receive(:has_highlight_field?).and_return(true)
        allow(document).to receive(:highlight_field).with('highlight').and_return(['<em>highlight</em>'.html_safe, '<em>other highlight</em>'.html_safe])
      end

      let(:field_name) { 'highlight' }

      it { is_expected.to eq '<em>highlight</em> and <em>other highlight</em>' }
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

    context 'when accessor is set to an array' do
      let(:field_name) { 'explicit_array_accessor' }

      it 'calls the accessors on the return of the preceeding' do
        allow(document).to receive_message_chain(:solr_doc_accessor, some_method: "123")

        expect(subject).to eq '123'
      end
    end
  end

  describe '#fields' do
    let(:field) { instance_double(Blacklight::Configuration::Field) }

    before do
      allow(config).to receive(:show_fields_for).and_return(title: field)
    end

    it 'returns the list from the configs' do
      expect(subject.send(:fields)).to eq(title: field)
    end
  end

  describe "#heading" do
    it "falls back to an id" do
      allow(document).to receive(:[]).with('id').and_return "xyz"
      expect(subject.heading).to eq document.id
    end

    it "returns the value of the field" do
      config.show.title_field = :x
      allow(document).to receive(:has?).with(:x).and_return(true)
      allow(document).to receive(:[]).with(:x).and_return("value")
      expect(subject.heading).to eq "value"
    end

    it "returns the first present value" do
      config.show.title_field = [:x, :y]
      allow(document).to receive(:has?).with(:x).and_return(false)
      allow(document).to receive(:has?).with(:y).and_return(true)
      allow(document).to receive(:[]).with(:y).and_return("value")
      expect(subject.heading).to eq "value"
    end
  end

  describe "#html_title" do
    it "falls back to an id" do
      allow(document).to receive(:[]).with('id').and_return "xyz"
      expect(subject.html_title).to eq document.id
    end

    it "returns the value of the field" do
      config.show.html_title_field = :x
      allow(document).to receive(:has?).with(:x).and_return(true)
      allow(document).to receive(:fetch).with(:x, nil).and_return("value")
      expect(subject.html_title).to eq "value"
    end

    it "returns the first present value" do
      config.show.html_title_field = [:x, :y]
      allow(document).to receive(:has?).with(:x).and_return(false)
      allow(document).to receive(:has?).with(:y).and_return(true)
      allow(document).to receive(:fetch).with(:y, nil).and_return("value")
      expect(subject.html_title).to eq "value"
    end
  end

  describe '#field_values' do
    context 'for a field with the helper_method option' do
      let(:field_name) { 'field_with_helper' }
      let(:field_config) { config.add_facet_field 'field_with_helper', helper_method: 'render_field_with_helper' }
      let(:document) do
        SolrDocument.new(id: 1, 'field_with_helper' => 'value')
      end

      it "checks call the helper method with arguments" do
        allow(request_context).to receive(:render_field_with_helper) do |*args|
          args.first
        end

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
