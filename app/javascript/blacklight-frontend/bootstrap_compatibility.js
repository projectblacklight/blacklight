import Core from 'blacklight-frontend/core'

// Bootstrap 6's Menu replaced Bootstrap 5's Dropdown data API. Its CSS
// exposes --bs-bg-body; Bootstrap 5 instead exposes --bs-body-bg.
const useBootstrap6 = () => getComputedStyle(document.documentElement).getPropertyValue('--bs-bg-body').trim() !== ''

const BootstrapCompatibility = () => {
  const version = useBootstrap6() ? '6' : '5'
  // Version-specific Blacklight CSS uses this attribute on <html>.
  document.documentElement.dataset.blBootstrapVersion = version

  // Marked buttons start with Bootstrap 5's dropdown toggle in the HTML.
  // Bootstrap 6 renamed that data API to menu, so update them after each load.
  const toggle = version === '6' ? 'menu' : 'dropdown'
  document.querySelectorAll('[data-bl-bs-toggle="menu"]').forEach(button => {
    button.setAttribute('data-bs-toggle', toggle)
  })
}

// Core runs this on the first page load and after Turbo navigation.
Core.onLoad(BootstrapCompatibility)

export default BootstrapCompatibility
