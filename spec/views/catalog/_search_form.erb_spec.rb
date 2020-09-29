# frozen_string_literal: true

# spec for search form input view

RSpec.describe "/catalog/_search_form.html.erb" do
  it "renders aria label for search input" do
    stub_template "_search_form.html.erb" => "search_form"
    render
    expect(rendered).to include("aria-label='search'")
  end
end
