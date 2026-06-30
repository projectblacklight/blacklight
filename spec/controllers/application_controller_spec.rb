# frozen_string_literal: true

# Blacklight manages its own guest users only when no other provider (such as
# the devise-guests gem) is present. Under Devise, current_or_guest_user defers
# to devise-guests, so the guest-fallback specs below run on the Rails
# authentication test app only.
BLACKLIGHT_MANAGES_GUESTS = !defined?(DeviseGuests)

RSpec.describe ApplicationController do
  describe "#blacklight_config" do
    it "provides a default blacklight_config everywhere" do
      expect(controller.blacklight_config).to eq CatalogController.blacklight_config
    end
  end

  describe "authentication path helpers" do
    it "prefers Devise routes when available" do
      allow(controller).to receive(:respond_to?).and_call_original
      allow(controller).to receive(:respond_to?).with(:new_user_session_path).and_return(true)
      allow(controller).to receive(:new_user_session_path).and_return("/users/sign_in")

      expect(controller.send(:blacklight_login_path)).to eq "/users/sign_in"
    end

    it "falls back to Rails authentication routes" do
      allow(controller).to receive(:respond_to?).and_call_original
      allow(controller).to receive(:respond_to?).with(:new_user_session_path).and_return(false)
      allow(controller).to receive(:respond_to?).with(:new_session_path).and_return(true)
      allow(controller).to receive(:new_session_path).and_return("/session/new")

      expect(controller.send(:blacklight_login_path)).to eq "/session/new"
    end

    it "uses a DELETE logout link for Rails authentication" do
      allow(controller).to receive(:respond_to?).and_call_original
      allow(controller).to receive(:respond_to?).with(:destroy_user_session_path).and_return(false)
      allow(controller).to receive(:respond_to?).with(:session_path).and_return(true)
      allow(controller).to receive(:session_path).and_return("/session")

      expect(controller.send(:blacklight_logout_path)).to eq "/session"
      expect(controller.send(:blacklight_logout_link_options)).to eq(data: { turbo_method: :delete })
    end
  end

  describe "#current_or_guest_user and #guest_user" do
    it "returns the current user when one is signed in" do
      user = create_user(email: "signed_in@example.com", password: "password12345")
      allow(controller).to receive(:current_user).and_return(user)

      expect(controller.send(:current_or_guest_user)).to eq user
      expect { controller.send(:current_or_guest_user) }.not_to(change { User.where("#{User.blacklight_email_column} LIKE 'guest_%'").count })
    end

    # Blacklight only manages its own guest users when no other provider (such
    # as the devise-guests gem) is doing so. Under Devise, current_or_guest_user
    # defers to devise-guests, so these fallback behaviors are exercised on the
    # Rails authentication test app instead.
    context "when Blacklight manages guest users", if: BLACKLIGHT_MANAGES_GUESTS do
      it "creates and memoizes a persisted guest user for anonymous visitors" do
        session = {}
        allow(controller).to receive_messages(current_user: nil, session: session)

        guest = controller.send(:current_or_guest_user)

        expect(guest).to be_persisted
        expect(session[:blacklight_guest_user_id]).to eq guest.id
        expect(guest.public_send(User.blacklight_email_column)).to match(/^guest_.*@example\.com$/)

        expect(controller.send(:current_or_guest_user)).to eq guest
      end

      it "reuses an existing guest across requests via the session" do
        existing = User.create_guest_user!
        allow(controller).to receive_messages(current_user: nil, session: { blacklight_guest_user_id: existing.id })

        expect(controller.send(:current_or_guest_user)).to eq existing
      end
    end
  end
end
