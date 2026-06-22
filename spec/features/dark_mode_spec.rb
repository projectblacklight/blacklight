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
end
