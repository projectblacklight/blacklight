# frozen_string_literal: true

RSpec.describe "shared/_user_util_links" do

  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.navbar.partials = { bookmark: Blacklight::Configuration::ToolConfig.new(partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?) }
    end

  end

  it "renders the correct bookmark count" do
    count = rand(99)
    allow(view).to receive(:blacklight_config).and_return(blacklight_config)
    allow(controller).to receive(:render_bookmarks_control?).and_return true
    allow(view).to receive(:has_user_authentication_provider?).and_return false
    allow(view).to receive_message_chain(:current_or_guest_user, :bookmarks, :count).and_return(count)
    render "shared/user_util_links"
    expect(rendered).to have_selector('#bookmarks_nav span.tag[data-role=bookmark-counter]', text: "#{count}")
  end

end
