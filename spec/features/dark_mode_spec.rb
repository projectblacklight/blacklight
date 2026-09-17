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

  # Embedded webviews (e.g. Android WebView with DOM storage disabled) expose
  # window.localStorage as null, and some browsers throw when it is accessed.
  context 'when localStorage is unavailable' do
    # The theme switcher falls back to the browser's preferred color scheme when
    # it has no stored theme to use.
    let(:preferred_theme) do
      page.evaluate_script("window.matchMedia('(prefers-color-scheme: dark)').matches") ? 'dark' : 'light'
    end
    let(:other_theme) { preferred_theme == 'dark' ? 'light' : 'dark' }

    def disable_local_storage
      page.execute_script("Object.defineProperty(window, 'localStorage', { get: () => null })")
    end

    def select_theme(theme)
      find_by_id('bl-theme-switcher').click
      find(%([data-bs-theme-value="#{theme}"])).click
    end

    it 'still applies the selected theme' do
      visit root_path
      expect(page).to have_css(%(html[data-bs-theme="#{preferred_theme}"]))

      disable_local_storage
      select_theme(other_theme)

      expect(page).to have_css(%(html[data-bs-theme="#{other_theme}"]))
    end

    it 'falls back to the preferred color scheme when the stored theme cannot be read' do
      visit root_path
      select_theme(other_theme)
      expect(page).to have_css(%(#bl-theme-switcher[aria-label="Toggle theme (#{other_theme})"]))

      disable_local_storage

      # Turbo fires turbo:load on every page transition, which is when the
      # stored theme is read.
      page.execute_script("document.dispatchEvent(new Event('turbo:load'))")

      expect(page).to have_css(%(#bl-theme-switcher[aria-label="Toggle theme (#{preferred_theme})"]))
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
