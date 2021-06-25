//change form submit toggle to checkbox
Blacklight.doBookmarkToggleBehavior = function() {
  if (typeof Blacklight.do_bookmark_toggle_behavior == 'function') {
    console.warn("do_bookmark_toggle_behavior is deprecated. Use doBookmarkToggleBehavior instead.");
    return Blacklight.do_bookmark_toggle_behavior();
  }
  document.querySelectorAll(Blacklight.doBookmarkToggleBehavior.selector).forEach((el) => {
    new CheckboxSubmit(el).render()
  })
};
Blacklight.doBookmarkToggleBehavior.selector = 'form.bookmark-toggle';

Blacklight.onLoad(function() {
  Blacklight.doBookmarkToggleBehavior();
});
