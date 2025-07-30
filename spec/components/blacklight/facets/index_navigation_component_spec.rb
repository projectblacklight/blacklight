# frozen_string_literal: true

RSpec.describe Blacklight::Facets::IndexNavigationComponent, type: :component do
  let(:pagination) { Blacklight::Solr::FacetPaginator.new([]) }
  let(:facet) { Blacklight::Configuration::FacetField.new(index_range: '0'..'9', presenter: Blacklight::FacetFieldPresenter) }
  let(:display_facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField, items: [], offset: 0, prefix: '', sort: 'index', index?: true) }
  let(:blacklight_config) { Blacklight::Configuration.new }

  let(:presenter) { facet.presenter.new(facet, display_facet, vc_test_controller.view_context) }

  before do
    with_request_url "/catalog/facet/language" do
      render_inline(described_class.new(presenter: presenter))
    end
  end

  it 'renders the facet index navigation range' do
    expect(page).to have_css '.pagination'
    facet_path = ViewComponent::VERSION::MAJOR == 3 ? '/catalog/facet/language.html' : '/catalog/facet/language'
    expect(page).to have_link '0', href: "#{facet_path}?facet.prefix=0&facet.sort=index"
    expect(page).to have_link '1'
    expect(page).to have_link '8'
    expect(page).to have_link '9'
  end

  it 'renders an "all" button' do
    expect(page).to have_css '.page-link', text: 'All'
  end

  context 'with a selected index' do
    let(:display_facet) { instance_double(Blacklight::Solr::Response::Facets::FacetField, items: [], offset: 0, prefix: '5', sort: 'index', index?: true) }

    it 'highlights the selected index' do
      expect(page).to have_css '.active', text: '5'
    end

    it 'enables the clear facets button' do
      expect(page).to have_link 'All'
    end
  end
end
