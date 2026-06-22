/*!
 * Color mode toggler for Blacklight
 * Based on Bootstrap's color mode toggler (https://getbootstrap.com/docs/5.3/customize/color-modes/#javascript)
 */

import Core from 'blacklight-frontend/core'

const ColorThemeSwitcher = (() => {
  'use strict'

  const getStoredTheme = () => localStorage.getItem('theme')
  const setStoredTheme = theme => localStorage.setItem('theme', theme)

  const getPreferredTheme = () => {
    const storedTheme = getStoredTheme()
    if (storedTheme) {
      return storedTheme
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light'
  }

  const setTheme = theme => {
    if (theme === 'auto') {
      document.documentElement.setAttribute('data-bs-theme', window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light')
    } else {
      document.documentElement.setAttribute('data-bs-theme', theme)
    }
  }

  const showActiveTheme = (theme, focus = false) => {
    const themeSwitcher = document.querySelector('#bl-theme-switcher')
    if (!themeSwitcher) return

    // Reset all dropdown items
    document.querySelectorAll('[data-bs-theme-value]').forEach(element => {
      element.classList.remove('active')
      element.setAttribute('aria-pressed', 'false')
      const check = element.querySelector('.bl-theme-check')
      if (check) check.classList.add('d-none')
    })

    // Activate the selected item
    const btnToActive = document.querySelector(`[data-bs-theme-value="${theme}"]`)
    if (btnToActive) {
      btnToActive.classList.add('active')
      btnToActive.setAttribute('aria-pressed', 'true')
      const check = btnToActive.querySelector('.bl-theme-check')
      if (check) check.classList.remove('d-none')
    }

    // Swap the toggle button icon
    themeSwitcher.querySelectorAll('.bl-theme-icon').forEach(icon => icon.classList.add('d-none'))
    const activeIcon = themeSwitcher.querySelector(`.bl-theme-icon[data-bl-theme-icon="${theme}"]`)
    if (activeIcon) activeIcon.classList.remove('d-none')

    themeSwitcher.setAttribute('aria-label', `Toggle theme (${theme})`)

    if (focus) {
      themeSwitcher.focus()
    }
  }

  window.matchMedia('(prefers-color-scheme: dark)').addEventListener('change', () => {
    const storedTheme = getStoredTheme()
    if (storedTheme !== 'light' && storedTheme !== 'dark') {
      setTheme(getPreferredTheme())
    }
  })

  document.addEventListener('click', e => {
    const btn = e.target.closest('[data-bs-theme-value]')
    if (!btn) return

    const theme = btn.getAttribute('data-bs-theme-value')
    setStoredTheme(theme)
    setTheme(theme)
    showActiveTheme(theme, true)
  })

  Core.onLoad(() => showActiveTheme(getPreferredTheme()))

  return { setTheme, getPreferredTheme, showActiveTheme }
})()

export default ColorThemeSwitcher
