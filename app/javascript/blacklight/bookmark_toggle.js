import Blacklight from './core'
import CheckboxSubmit from 'blacklight/checkbox_submit'

const BookmarkToggle = (() => {
    // change form submit toggle to checkbox
    Blacklight.doBookmarkToggleBehavior = function() {
      document.querySelectorAll(Blacklight.doBookmarkToggleBehavior.selector).forEach((el) => {
        new CheckboxSubmit(el).render()
      })
    };
    Blacklight.doBookmarkToggleBehavior.selector = 'form.bookmark-toggle';

    Blacklight.onLoad(function() {
      Blacklight.doBookmarkToggleBehavior();
    });
})()

export default BookmarkToggle
