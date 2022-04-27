# frozen_string_literal: true

RSpec.describe "catalog/sms_success.html.erb" do
  it "includes updates to the main flash messages" do
    render
    expect(rendered).to have_selector 'turbo-stream[action="append"][target="main-flashes"]'
  end
end
