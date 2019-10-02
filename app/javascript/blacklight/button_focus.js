Blacklight.onLoad(function() {
  // Button clicks should change focus. As of 10/2/19, Firefox for Mac and
  // Safari both do not do this correctly.
  document.addEventListener('click', event => {
    if (event.target.matches('button')) {
      event.target.focus();
    }
  });
});
