# frozen_string_literal: true

RSpec.describe 'catalog/_facet_index_navigation.html.erb', type: :view do
  let(:pagination) { Blacklight::Solr::FacetPaginator.new([]) }
  let(:facet) { Blacklight::Configuration::FacetField.new(index_range: '0'..'9') }
  let(:display_facet) { double(items: [], offset: 0, prefix: '', sort: 'index') }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    assign(:display_facet, display_facet)
    assign(:facet, facet)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:facet_limit_for).and_return(10)
    controller.request.path_parameters[:action] = 'index'
  end

  it 'renders the facet index navigation range' do
    render
    expect(rendered).to have_selector '.pagination'
    expect(rendered).to have_link '0', href: '/?facet.prefix=0&facet.sort=index'
    expect(rendered).to have_link '1'
    expect(rendered).to have_link '8'
    expect(rendered).to have_link '9'
  end

  it 'renders an "all" button' do
    render
    expect(rendered).to have_selector '.page-link', text: 'All'
  end

  context 'with a selected index' do
    let(:display_facet) { double(items: [], offset: 0, prefix: '5', sort: 'index') }

    it 'highlights the selected index' do
      render
      expect(rendered).to have_selector '.active', text: '5'
    end

    it 'enables the clear facets button' do
      render
      expect(rendered).to have_link 'All'
    end
  end
end
