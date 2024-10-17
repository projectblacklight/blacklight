const ButtonFocus = (e) => {
  // Button clicks should change focus. As of 10/3/19, Firefox for Mac and
  // Safari both do not set focus to a button on button click.
  // See https://zellwk.com/blog/inconsistent-button-behavior/ for background information
  if (e.target.matches('[data-toggle="collapse"]') || e.target.matches('[data-bs-toggle="collapse"]')) {
    e.target.focus()
  }
}

document.addEventListener('click', ButtonFocus)

export default ButtonFocus
