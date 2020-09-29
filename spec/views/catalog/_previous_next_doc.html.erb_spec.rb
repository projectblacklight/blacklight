# frozen_string_literal: true

RSpec.describe "catalog/_previous_next_doc.html.erb" do
  before do
    allow(view).to receive(:search_session).and_return({})
  end

  it "without next or previous does not render content" do
    assign(:search_context, {})
    render
    expect(rendered).not_to have_selector ".pagination-search-widgets"
  end

  it "with next or previous does render content" do
    assign(:search_context, next: 'foo', prev: 'bar')
    allow(view).to receive(:link_to_previous_document).and_return('')
    allow(view).to receive(:item_page_entry_info).and_return('')
    allow(view).to receive(:link_to_next_document).and_return('')
    render
    expect(rendered).to have_selector ".pagination-search-widgets"
  end
end
