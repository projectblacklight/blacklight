# frozen_string_literal: true

# spec/support/features/turbo_helpers.rb
module Features
  module TurboHelpers
    # Turbo Drive marks the document as busy for the duration of a visit. Capybara
    # clicks return before the visit completes, so wait for the busy state to clear
    # before making assertions that don't wait on their own (e.g. be_axe_clean).
    def wait_for_turbo
      expect(page).to have_no_css('html[aria-busy]', visible: :all)
    end
  end
end
