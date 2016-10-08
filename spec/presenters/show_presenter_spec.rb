# frozen_string_literal: true

RSpec.describe Blacklight::ShowPresenter do
  include Capybara::RSpecMatchers
  let(:view_context) { double(search_state: search_state) }
  let(:config) { Blacklight::Configuration.new }

  subject { presenter }
  let(:presenter) { described_class.new(document, view_context, config) }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:controller) { double }
  let(:search_state) { Blacklight::SearchState.new(params, config, controller) }

  let(:document) do
    SolrDocument.new(id: 1,
                     'link_to_facet_true' => 'x',
                     'link_to_facet_named' => 'x',
                     'qwer' => 'document qwer value',
                     'mnbv' => 'document mnbv value')
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
         def export_as_weird ; "weird" ; end
         def export_as_weirder ; "weirder" ; end
         def export_as_weird_dup ; "weird_dup" ; end
      end

      MockDocument.use_extension(MockExtension)

      def mock_document_app_helper_url *args
        solr_document_url(*args)
      end

      allow(view_context).to receive(:polymorphic_url) do |_, opts|
        "url.#{opts[:format]}"
      end
    end

    let(:document) { MockDocument.new(id: "MOCK_ID1") }

    context "with no arguments" do
      subject { presenter.link_rel_alternates }

      it "generates <link rel=alternate> tags" do
        tmp_value = Capybara.ignore_hidden_elements
        Capybara.ignore_hidden_elements = false
        document.export_formats.each_pair do |format, spec|
          expect(subject).to have_selector("link[href$='.#{ format  }']") do |matches|
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
        expect(subject).to_not have_selector("link[href$='.weird_dup']")
        Capybara.ignore_hidden_elements = tmp_value
      end
    end
  end

  describe "#render_field?" do
    before do
      allow(view_context).to receive_messages(should_render_field?: true, document_has_value?: true)
    end

    it "is true" do
      expect(presenter.render_field?(double)).to be true
    end

    it "is false if the document doesn't have a value for the field" do
      allow(view_context).to receive_messages(document_has_value?: false)
      expect(presenter.render_field?(double)).to be false
    end

    it "is false if the configuration has the field disabled" do
      allow(view_context).to receive_messages(should_render_field?: false)
      expect(presenter.render_field?(double)).to be false
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
end
