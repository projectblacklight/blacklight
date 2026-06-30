# frozen_string_literal: true

RSpec.describe "shared/_user_util_links" do
  let(:blacklight_config) do
    Blacklight::Configuration.new.configure do |config|
      config.navbar.partials = { bookmark: Blacklight::Configuration::ToolConfig.new(partial: 'blacklight/nav/bookmark', if: :render_bookmarks_control?) }
    end
  end

  before do
    allow(controller).to receive(:render_bookmarks_control?).and_return false
  end

  it "renders the correct bookmark count" do
    count = rand(99)
    allow(controller).to receive(:render_bookmarks_control?).and_return true
    allow(view).to receive_messages(blacklight_config: blacklight_config, has_user_authentication_provider?: false)
    allow(view).to receive_message_chain(:current_or_guest_user, :bookmarks, :count).and_return(count)
    render "shared/user_util_links"
    expect(rendered).to have_css('#bookmarks_nav span.badge[data-role=bookmark-counter]', text: count.to_s)
  end

  it "renders Rails authentication session links" do
    user = instance_double(User, to_s: "xyz@example.com")

    allow(view).to receive_messages(
      blacklight_account_path: nil,
      blacklight_config: blacklight_config,
      blacklight_login_path: "/session/new",
      blacklight_logout_link_options: { data: { turbo_method: :delete } },
      blacklight_logout_path: "/session",
      current_user: user,
      has_user_authentication_provider?: true
    )

    render "shared/user_util_links"

    expect(rendered).to have_link("Log Out", href: "/session")
    expect(rendered).to have_css('a[data-turbo-method="delete"]', text: "Log Out")
    expect(rendered).to have_no_link("xyz@example.com")
  end

  it "renders Devise-compatible session and registration links" do
    user = instance_double(User, to_s: "xyz@example.com")

    allow(view).to receive_messages(
      blacklight_account_path: "/users/edit",
      blacklight_config: blacklight_config,
      blacklight_login_path: "/users/sign_in",
      blacklight_logout_link_options: {},
      blacklight_logout_path: "/users/sign_out",
      current_user: user,
      has_user_authentication_provider?: true
    )

    render "shared/user_util_links"

    expect(rendered).to have_link("Log Out", href: "/users/sign_out")
    expect(rendered).to have_link("xyz@example.com", href: "/users/edit")
  end

  it "renders a provider-neutral login link" do
    allow(view).to receive_messages(
      blacklight_config: blacklight_config,
      blacklight_login_path: "/session/new",
      current_user: nil,
      has_user_authentication_provider?: true
    )

    render "shared/user_util_links"

    expect(rendered).to have_link("Login", href: "/session/new")
  end
end
