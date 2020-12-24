# frozen_string_literal: true

RSpec.describe Blacklight::IndexPresenter, api: true do
  include Capybara::RSpecMatchers
  subject { presenter }

  let(:request_context) { double('context', document_index_view_type: 'list', session_tracking_params: {}, link_to: '<a>'.html_safe) }
  let(:config) { Blacklight::Configuration.new }

  let(:presenter) { described_class.new(document, request_context, config) }
  let(:parameter_class) { ActionController::Parameters }
  let(:params) { parameter_class.new }
  let(:controller) { double("controller") }
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

  describe '#fields' do
    let(:field) { instance_double(Blacklight::Configuration::Field) }

    before do
      allow(config).to receive(:index_fields_for).and_return(title: field)
    end

    it 'returns the list from the configs' do
      expect(subject.send(:fields)).to eq(title: field)
    end
  end

  describe "#thumbnail" do
    subject { presenter.thumbnail }

    it { is_expected.to be_instance_of Blacklight::ThumbnailPresenter }
  end

  describe '#display_type' do
    context 'with no configuration' do
      it 'returns an empty array' do
        expect(presenter.display_type).to be_empty
      end
    end

    context 'with a default value' do
      it 'returns the default' do
        expect(presenter.display_type(default: 'default')).to eq ['default']
      end
    end

    context 'with field configuration' do
      let(:document) do
        SolrDocument.new(id: 1, xyz: 'abc')
      end

      before do
        config.index.display_type_field = :xyz
      end

      it 'returns the value from the field' do
        expect(presenter.display_type).to eq ['abc']
      end
    end
  end

  describe "#link_to_document" do
    let(:title_tsim) { '654321' }
    let(:id) { '123456' }
    let(:data) { { 'id' => id, 'title_tsim' => [title_tsim] } }
    let(:document) { SolrDocument.new(data) }

    before do
      allow(controller).to receive(:action_name).and_return('index')
      allow(request_context).to receive(:track_test_path).and_return('tracking url')
      allow(request_context).to receive(:respond_to?).with('track_test_path').and_return(true)
    end

    it "accepts and returns a string label" do
      presenter.link_to_document 'This is the title'
      expect(request_context).to have_received(:link_to).with('This is the title', document, {})
    end

    context 'when label is missing' do
      let(:data) { { 'id' => id } }

      it "returns id" do
        presenter.link_to_document
        expect(request_context).to have_received(:link_to).with('123456', document, {})
      end

      it "passes on the title attribute to the link_to_with_data method" do
        presenter.link_to_document("Some crazy long label...", title: "Some crazy longer label")
        expect(request_context).to have_received(:link_to).with('Some crazy long label...', document, { title: "Some crazy longer label" })
      end

      context "with an integer id" do
        let(:id) { 123_456 }

        it "works" do
          presenter.link_to_document
          expect(request_context).to have_received(:link_to).with('123456', document, {})
        end
      end
    end

    it "converts the counter parameter into a data- attribute" do
      allow(request_context).to receive(:session_tracking_params).and_return({ 'data-context-href': '5' })

      presenter.link_to_document('foo', counter: 5)
      expect(request_context).to have_received(:link_to).with('foo', document, { "data-context-href": "5" })
    end

    it "includes the data- attributes from the options" do
      presenter.link_to_document data: { x: 1 }
      expect(request_context).to have_received(:link_to).with('123456', document, { data: { x: 1 } })
    end
  end
end
