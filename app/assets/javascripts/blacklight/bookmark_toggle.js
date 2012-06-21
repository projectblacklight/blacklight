//= require blacklight/core
//= require blacklight/checkbox_submit
(function($) {
//change form submit toggle to checkbox
    Blacklight.do_bookmark_toggle_behavior = function() {
      $(Blacklight.do_bookmark_toggle_behavior.selector).bl_checkbox_submit({          
          checked_label: "In Bookmarks",
          unchecked_label: "Bookmark",
          progress_label: "Saving...",
          //css_class is added to elements added, plus used for id base
          css_class: "toggle_bookmark"    
      }); 
    };
    Blacklight.do_bookmark_toggle_behavior.selector = "form.bookmark_toggle"; 

$(document).ready(function() {
  Blacklight.do_bookmark_toggle_behavior();  
});
  

})(jQuery);
