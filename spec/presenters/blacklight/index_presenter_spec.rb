# frozen_string_literal: true

RSpec.describe Blacklight::IndexPresenter, api: true do
  include Capybara::RSpecMatchers
  subject { presenter }

  let(:request_context) { double(document_index_view_type: 'list') }
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

  describe '#fields' do
    before do
      config.add_index_field 'title'
    end

    it 'returns the list from the configs' do
      expect(subject.send(:fields).keys).to eq ['title']
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
end
