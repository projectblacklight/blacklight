(function($) {
    Blacklight.do_folder_toggle_behavior = function() {
      $( Blacklight.do_folder_toggle_behavior.selector ).bl_checkbox_submit({
          checked_label: "Selected",
          unchecked_label: "Select",
          css_class: "toggle_folder",
          success: function(new_state) {
            
            if (new_state) {
               $("#folder_number").text(parseInt($("#folder_number").text()) + 1);
            }
            else {
               $("#folder_number").text(parseInt($("#folder_number").text()) - 1);
            }
          }
      });
    };
    Blacklight.do_folder_toggle_behavior.selector = "form.folder_toggle"; 
})(jQuery);
