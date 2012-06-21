(function($) {
// Used for sort-by and per-page controls, hide the submit button
    // and make the select auto-submit
    Blacklight.do_select_submit = function() {
      $(Blacklight.do_select_submit.selector).each(function() {
          var select = $(this);
          select.closest("form").find("input[type=submit]").hide();
          select.bind("change", function() {
              this.form.submit();
          });
      });
    };
    Blacklight.do_select_submit.selector = "form.sort select, form.per_page select";
$(document).ready(function() {
  Blacklight.do_select_submit();  
});
    })(jQuery);
