# frozen_string_literal: true

RSpec.describe "catalog/email_success.html.erb" do
  it "includes updates to the main flash messages" do
    render
    expect(rendered).to have_css 'turbo-stream[action="append"][target="main-flashes"]'
  end
end
