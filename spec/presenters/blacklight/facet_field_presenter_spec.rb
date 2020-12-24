# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Blacklight::FacetFieldPresenter, type: :presenter do
  subject(:presenter) do
    described_class.new(facet_field, display_facet, view_context, search_state)
  end

  let(:facet_field) { Blacklight::Configuration::FacetField.new(key: 'key') }
  let(:display_facet) do
    instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, sort: :index, offset: 0, prefix: nil)
  end
  let(:items) { [] }
  let(:view_context) { controller.view_context }
  let(:search_state) { view_context.search_state }

  before do
    allow(view_context).to receive(:facet_limit_for).and_return(20)
  end

  describe '#collapsed?' do
    it "is collapsed by default" do
      facet_field.collapse = true
      expect(presenter.collapsed?).to be true
    end

    it "does not be collapse if the configuration says so" do
      facet_field.collapse = false
      expect(presenter).not_to be_collapsed
    end

    it "does not be collapsed if it is in the params" do
      controller.params[:f] = ActiveSupport::HashWithIndifferentAccess.new(key: [1])
      expect(presenter.collapsed?).to be false
    end
  end

  describe '#active?' do
    it "checks if any value is selected for a given facet" do
      controller.params[:f] = ActiveSupport::HashWithIndifferentAccess.new(key: [1])
      expect(presenter.active?).to eq true
    end

    it "is false if no value for facet is selected" do
      expect(presenter.active?).to eq false
    end
  end

  describe '#in_modal?' do
    context 'for a modal-like action' do
      before do
        controller.params[:action] = 'facet'
      end

      it 'is true' do
        expect(presenter.in_modal?).to eq true
      end
    end

    it 'is false' do
      expect(presenter.in_modal?).to eq false
    end
  end

  describe '#modal_path' do
    let(:paginator) { Blacklight::FacetPaginator.new([{}, {}], limit: 1) }

    before do
      # rubocop:disable RSpec/SubjectStub
      allow(presenter).to receive(:paginator).and_return(paginator)
      # rubocop:enable RSpec/SubjectStub
    end

    context 'with no additional data' do
      let(:paginator) { Blacklight::FacetPaginator.new([{}, {}], limit: 10) }

      it 'is nil' do
        expect(presenter.modal_path).to be_nil
      end
    end

    it 'returns the path to the facet view' do
      allow(view_context).to receive(:search_facet_path).with(id: 'key').and_return('/catalog/facet/key')

      expect(presenter.modal_path).to eq '/catalog/facet/key'
    end
  end

  describe '#label' do
    it 'gets the label from the helper' do
      allow(view_context).to receive(:facet_field_label).with('key').and_return('Label')
      expect(presenter.label).to eq 'Label'
    end
  end

  describe '#paginator' do
    subject(:paginator) { presenter.paginator }

    it 'return a paginator for the facet data' do
      expect(paginator.current_page).to eq 1
      expect(paginator.total_count).to eq 0
    end
  end

  describe "#facet_limit" do
    subject(:facet_limit) { presenter.facet_limit }

    let(:search_state) { Blacklight::SearchState.new({}, blacklight_config, controller) }
    let(:blacklight_config) { CatalogController.blacklight_config }
    let(:facet_field) { blacklight_config.facet_fields['subject_ssim'] }
    let(:display_facet) do
      instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, limit: nil, sort: :index, offset: 0, prefix: nil)
    end
    # let(:facet_field) { Blacklight::Configuration::FacetField.new(key: 'key') }
    # let(:display_facet) do
    #   instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, sort: :index, offset: 0, prefix: nil)
    # end

    it "returns specified value for facet_field specified" do
      expect(facet_limit).to eq facet_field.limit
    end

    describe "for 'true' configured values" do
      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field "language_facet", limit: true
        end
      end
      let(:facet_field) { blacklight_config.facet_fields['language_facet'] }

      context 'when the limit in the response is nil' do
        let(:display_facet) do
          instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, limit: nil, sort: :index, offset: 0, prefix: nil)
        end

        it "uses the config setting" do
          blacklight_config.facet_fields['language_facet'].limit = 10
          expect(facet_limit).to eq 10
        end
      end

      context 'when the limit in the response is provided' do
        let(:display_facet) do
          instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, limit: 16, sort: :index, offset: 0, prefix: nil)
        end

        it "gets the limit from the facet field in @response" do
          expect(facet_limit).to eq 15
        end
      end

      context 'when not in the display_facet' do
        let(:display_facet) { nil }

        it "defaults to 10" do
          expect(facet_limit).to eq 10
        end
      end
    end

    context 'for facet fields with a key that is different from the field name' do
      before do
        allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
      end

      let(:blacklight_config) do
        Blacklight::Configuration.new do |config|
          config.add_facet_field 'some_key', field: 'x', limit: true
        end
      end
      let(:facet_field) { blacklight_config.facet_fields['some_key'] }
      let(:display_facet) do
        instance_double(Blacklight::Solr::Response::Facets::FacetField, items: items, limit: 16, sort: :index, offset: 0, prefix: nil)
      end

      it 'gets the limit from the facet field in the @response' do
        expect(facet_limit).to eq 15
      end
    end
  end
end
