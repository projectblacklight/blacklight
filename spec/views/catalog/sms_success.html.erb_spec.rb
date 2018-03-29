# frozen_string_literal: true

RSpec.describe "catalog/sms_success.html.erb" do

  it "includes the data-blacklight-modal properties" do
    render
    expect(rendered).to have_selector "div[data-blacklight-modal=container]"
  end
end
