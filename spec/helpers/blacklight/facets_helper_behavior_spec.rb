# frozen_string_literal: true

RSpec.describe Blacklight::FacetsHelperBehavior do
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    allow(helper).to receive(:blacklight_config).and_return blacklight_config
  end

  describe '#facet_field_presenter' do
    let(:facet_config) { Blacklight::Configuration::FacetField.new(key: 'x').normalize! }
    let(:display_facet) { double }

    it 'wraps the facet data in a presenter' do
      presenter = helper.facet_field_presenter(facet_config, display_facet)
      expect(presenter).to be_a_kind_of Blacklight::FacetFieldPresenter
      expect(presenter.facet_field).to eq facet_config
      expect(presenter.display_facet).to eq display_facet
      expect(presenter.view_context).to eq helper
    end

    it 'uses the facet config to determine the presenter class' do
      stub_const('SomePresenter', Class.new(Blacklight::FacetFieldPresenter))
      facet_config.presenter = SomePresenter
      presenter = helper.facet_field_presenter(facet_config, display_facet)
      expect(presenter).to be_a_kind_of SomePresenter
    end
  end
end
