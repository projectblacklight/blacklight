# frozen_string_literal: true

RSpec.describe Blacklight::ShowPresenter, api: true do
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
    SolrDocument.new(id: 'xyz', some_field: 'value')
  end

  before do
    allow(request_context).to receive(:search_state).and_return(search_state)
    allow(request_context).to receive(:action_name).and_return(:show)
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
          expect(subject).to have_selector("link[href$='.#{format}']", count: 1) do |tag|
            expect(tag["rel"]).to eq "alternate"
            expect(tag["title"]).to eq format.to_s
            expect(tag["href"]).to eq "url.#{format}"
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

  describe '#fields' do
    before do
      config.add_show_field 'title'
    end

    it 'returns the list from the configs' do
      expect(subject.send(:fields).keys).to eq ['title']
    end
  end

  describe "#heading" do
    it "falls back to an id" do
      expect(subject.heading).to eq document.id
    end

    it "returns the value of the field" do
      config.show.title_field = 'some_field'
      expect(subject.heading).to eq "value"
    end

    it "returns the first present value" do
      config.show.title_field = %w[a_field_that_doesnt_exist some_field]
      expect(subject.heading).to eq "value"
    end

    it "can use explicit field configuration" do
      config.show.title_field = Blacklight::Configuration::DisplayField.new(field: 'x', values: ->(*_) { 'hardcoded' })
      expect(subject.heading).to eq 'hardcoded'
    end

    context "with an empty document" do
      let(:document) { SolrDocument.new({}) }

      it "returns an empty string as the heading" do
        expect(subject.heading).to eq("")
      end
    end
  end

  describe "#html_title" do
    it "falls back to an id" do
      expect(subject.html_title).to eq document.id
    end

    it "returns the value of the field" do
      config.show.html_title_field = 'some_field'
      expect(subject.html_title).to eq "value"
    end

    it "returns the first present value" do
      config.show.html_title_field = %w[a_field_that_doesnt_exist some_field]
      expect(subject.html_title).to eq "value"
    end

    it "can use explicit field configuration" do
      config.show.html_title_field = Blacklight::Configuration::DisplayField.new(field: 'x', values: ->(*_) { 'hardcoded' })
      expect(subject.html_title).to eq 'hardcoded'
    end
  end
end
