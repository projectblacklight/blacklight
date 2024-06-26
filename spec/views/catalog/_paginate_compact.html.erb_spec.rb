# frozen_string_literal: true

RSpec.describe "catalog/_paginate_compact.html.erb" do
  let(:user) { User.new { |u| u.save(validate: false) } }
  let(:blacklight_config) { Blacklight::Configuration.new }

  before do
    controller.request.path_parameters[:action] = 'index'
    allow(controller).to receive(:blacklight_config).and_return(blacklight_config)
  end

  it "renders paginatable arrays" do
    render partial: 'catalog/paginate_compact', object: Kaminari.paginate_array([], total_count: 145).page(1).per(10)
    expect(rendered).to have_css ".page-entries"
    expect(rendered).to have_css "a[@rel=next]"
  end

  it "renders ActiveRecord collections" do
    50.times { b = Bookmark.new; b.user = user; b.save! }
    render partial: 'catalog/paginate_compact', object: Bookmark.page(1).per(25)
    expect(rendered).to have_css ".page-entries"
    expect(rendered).to have_css "a[@rel=next]"
  end
end
