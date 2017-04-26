# frozen_string_literal: true

RSpec.describe Blacklight::IndexPresenter do
  include Capybara::RSpecMatchers
  let(:document_url) { double("document-url") }
  let(:session_params) { { data: { :'tracker-href' => '/track/123' } } }

  let(:view_context) do
    double(search_state: search_state,
           document_index_view_type: :a,
           url_for_document: document_url,
           session_tracking_params: session_params,
          )
  end
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

  describe "#thumbnail" do
    subject { presenter.thumbnail }
    it { is_expected.to be_instance_of Blacklight::ThumbnailPresenter }
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


  describe "#link_to_document" do
    let(:title_display) { '654321' }
    let(:id) { '123456' }
    let(:data) { { 'id' => id, 'title_display' => [title_display] } }
    let(:document) { SolrDocument.new(data) }

    before do
      allow(view_context).to receive(:action_name).and_return('index')
    end

    it "consists of the document title wrapped in a <a>" do
      expect(view_context).to receive(:link_to).with('654321', document_url, session_params)
      presenter.link_to_document(:title_display)
    end

    it "accepts and returns a string label" do
      expect(view_context).to receive(:link_to).with('title_display', document_url, session_params)
      presenter.link_to_document(String.new('title_display'))
    end

    it "accepts and returns a Proc" do
      expect(view_context).to receive(:link_to).with('123456: 654321', document_url, session_params)
      presenter.link_to_document(Proc.new { |doc, opts| doc[:id] + ": " + doc.first(:title_display) })
    end

    context 'when label is missing' do
      let(:data) { { 'id' => id } }
      it "returns id" do
        expect(view_context).to receive(:link_to).with('123456', document_url, session_params)
        presenter.link_to_document
      end

      it "passes on the title attribute to the link_to_with_data method" do
        expect(view_context).to receive(:link_to).with('Some crazy long label...',
                                                       document_url,
                                                       data: {:"tracker-href"=>"/track/123"},
                                                       title: "Some crazy longer label")
        presenter.link_to_document("Some crazy long label...", title: "Some crazy longer label")
      end

      it "doesn't add an erroneous title attribute if one isn't provided" do
        expect(view_context).to receive(:link_to).with('Some crazy long label...',
                                                       document_url,
                                                       data: {:"tracker-href"=>"/track/123"})
        presenter.link_to_document("Some crazy long label...")
      end

      context "with an integer id" do
        let(:id) { 123456 }
        it "works" do
          expect(view_context).to receive(:link_to).with('123456', document_url, session_params)
          presenter.link_to_document
        end
      end
    end

    it "converts the counter parameter into a data- attribute" do
      allow(view_context).to receive(:session_tracking_params).with(document, 5).and_return(data: { context: "new-track" })
      expect(view_context).to receive(:link_to).with('654321', document_url, data: { context: "new-track" })
      presenter.link_to_document(:title_display, counter: 5)
    end

    it "includes the data- attributes from the options" do
      expect(view_context).to receive(:link_to).with('123456', document_url, data: { "tracker-href": "/track/123", x: 1 })
      presenter.link_to_document(data: { x: 1 })
    end
  end

  describe "#show_link_field" do
    let(:document) { SolrDocument.new id: 123, a: 1, b: 2, c: 3 }
    subject { presenter.show_link_field }

    it "allows single values" do
      config.index.title_field = :a
      expect(subject).to eq :a
    end

    it "retrieves the first field with data" do
      config.index.title_field = [:zzz, :b]
      expect(subject).to eq :b
    end

    it "falls back on the id" do
      config.index.title_field = [:zzz, :yyy]
      expect(subject).to eq 123
    end
  end
end
