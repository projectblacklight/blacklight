//= require blacklight/core
//= require blacklight/checkbox_submit
(function($) {
//change form submit toggle to checkbox
    Blacklight.do_bookmark_toggle_behavior = function() {
      $(Blacklight.do_bookmark_toggle_behavior.selector).bl_checkbox_submit({          
          checked_label: $('#checked_label').val(),
          unchecked_label: $('#unchecked_label').val(),
          progress_label: $('#progress_label').val(),
          //css_class is added to elements added, plus used for id base
          css_class: "toggle_bookmark"    
      }); 
    };
    Blacklight.do_bookmark_toggle_behavior.selector = "form.bookmark_toggle"; 

Blacklight.onLoad(function() {
  Blacklight.do_bookmark_toggle_behavior();  
});
  

})(jQuery);
