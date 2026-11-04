# frozen_string_literal: true

RSpec.describe 'Dark mode', :js do
  it 'sets data-bs-theme="dark" on the html element when dark mode is selected' do
    visit root_path

    find_by_id('bl-theme-switcher').click
    find('[data-bs-theme-value="dark"]').click

    expect(page).to have_css('html[data-bs-theme="dark"]')
  end

  it 'sets data-bs-theme="light" on the html element when light mode is selected' do
    visit root_path

    find_by_id('bl-theme-switcher').click
    find('[data-bs-theme-value="dark"]').click

    find_by_id('bl-theme-switcher').click
    find('[data-bs-theme-value="light"]').click

    expect(page).to have_css('html[data-bs-theme="light"]')
  end

  context 'when localStorage is unavailable' do
    before do
      # Simulate browsers where touching localStorage throws (e.g. Firefox's NS_ERROR_FAILURE
      # with corrupt profile storage, or a SecurityError when site data is blocked)
      page.driver.browser.execute_cdp(
        'Page.addScriptToEvaluateOnNewDocument',
        source: <<~JS
          Object.defineProperty(window, 'localStorage', {
            configurable: true,
            get() { throw new DOMException('Storage unavailable', 'SecurityError') }
          })
        JS
      )
    end

    it 'still initializes the theme and allows switching themes' do
      visit root_path

      expect(page).to have_css('html[data-bs-theme]')
      expect(page).to have_no_css('html.no-js')
      # showActiveTheme ran on load, so the preferred (OS-derived) theme is marked active
      expect(page).to have_css('[data-bs-theme-value][aria-pressed="true"]', visible: :all)

      find_by_id('bl-theme-switcher').click
      find('[data-bs-theme-value="dark"]').click

      expect(page).to have_css('html[data-bs-theme="dark"]')
    end
  end

  context 'when dark mode support is disabled in the configuration' do
    before do
      allow(Blacklight::Configuration).to receive(:new).and_wrap_original do |m, *args|
        config = m.call(*args)
        config.dark_mode_support = false
        config
      end
    end

    it 'uses light mode and does not render the theme switcher' do
      visit root_path

      expect(page).to have_link('Login') # avoid negation right after visiting
      expect(page).to have_no_css('html[data-bs-theme="dark"]')
      expect(page).to have_no_css('#bl-theme-switcher')
    end
  end
end
