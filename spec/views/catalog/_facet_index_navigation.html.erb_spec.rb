# frozen_string_literal: true

describe 'catalog/_facet_index_navigation.html.erb', type: :view do
  let(:pagination) { Blacklight::Solr::FacetPaginator.new([]) }
  let(:facet) { Blacklight::Configuration::FacetField.new({ index_range: '0'..'9' })}
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    assign(:pagination, pagination)
    assign(:facet, facet)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
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

  it 'renders a "clear filter" button' do
    render
    expect(rendered).to have_selector '.btn.disabled', text: 'Clear Filter'
  end

  context 'with a selected index' do
    let(:pagination) { Blacklight::Solr::FacetPaginator.new([], prefix: '5') }

    it 'highlights the selected index' do
      render
      expect(rendered).to have_selector '.active', text: '5'
    end
    it 'enables the clear facets button' do
      render
      expect(rendered).to have_link 'Clear Filter'
    end
  end
end
