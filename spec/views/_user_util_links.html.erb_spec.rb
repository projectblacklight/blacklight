require 'spec_helper'

describe "_user_util_links" do

  let :blacklight_config do
    Blacklight::Configuration.new
  end

  it "should render the correct bookmark count" do
    count = rand(99)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(view).to receive(:render_bookmarks_control?).and_return true
    allow(view).to receive(:has_user_authentication_provider?). and_return false
    allow(view).to receive_message_chain(:current_or_guest_user, :bookmarks, :count).and_return(count)  
    render :partial => "user_util_links"
    expect(rendered).to have_selector('#bookmarks_nav span[data-role=bookmark-counter]', text: "#{count}")
  end

end
