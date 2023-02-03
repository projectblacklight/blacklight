import Blacklight from 'blacklight/core'
import CheckboxSubmit from 'blacklight/checkbox_submit'

const BookmarkToggle = (() => {
    // change form submit toggle to checkbox
    Blacklight.doBookmarkToggleBehavior = function() {
      document.addEventListener('click', (e) => {
        if (e.target.matches('[data-checkboxsubmit-target="checkbox"]')) {
          const form = e.target.closest('form')
          if (form) new CheckboxSubmit(form).clicked(e);
        }
      });
    };
    Blacklight.doBookmarkToggleBehavior.selector = 'form.bookmark-toggle';

    Blacklight.doBookmarkToggleBehavior();
})()

export default BookmarkToggle
