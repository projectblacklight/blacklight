//= require blacklight/core
//= require blacklight/checkbox_submit
(function($) {
    //change form submit toggle to checkbox
    Blacklight.doBookmarkToggleBehavior = function() {
      if (typeof Blacklight.do_bookmark_toggle_behavior == 'function') {
        console.warn("do_bookmark_toggle_behavior is deprecated. Use doBookmarkToggleBehavior instead.");
        return Blacklight.do_bookmark_toggle_behavior();
      }
      $(Blacklight.doBookmarkToggleBehavior.selector).blCheckboxSubmit({
         // cssClass is added to elements added, plus used for id base
         cssClass: 'toggle-bookmark',
         success: function(checked, response) {
           if (response.bookmarks) {
             $('[data-role=bookmark-counter]').text(response.bookmarks.count);
           }
         }
      });
    };
    Blacklight.doBookmarkToggleBehavior.selector = 'form.bookmark-toggle';

Blacklight.onLoad(function() {
  Blacklight.doBookmarkToggleBehavior();
});


})(jQuery);
