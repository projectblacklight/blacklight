Blacklight.onLoad(function() {
  // Button clicks should change focus. As of 10/3/19, Firefox for Mac and
  // Safari both do not set focus to a button on button click.
  // See https://zellwk.com/blog/inconsistent-button-behavior/ for background information
  document.querySelectorAll('button.collapse-toggle').forEach((button) => {
    button.addEventListener('click', () => {
      event.target.focus();
    });
  });
});
