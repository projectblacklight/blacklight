//= require blacklight/core
(function($) {
// Used for sort-by and per-page controls, hide the submit button
    // and make the select auto-submit
    Blacklight.update_css_dropdown = function(dropdown, prefix, suffix) {
      $(dropdown).find('ul.css-dropdown ul a').click (function (e) {
        selection_key = $(this).text();
        
        $(dropdown).find('ul.css-dropdown li.btn>a').html(prefix + selection_key + suffix);
      });

    }

$(document).ready(function() {
  $('#sort-form').hide();
  $('#sort-dropdown').show();
  Blacklight.update_css_dropdown('#sort-dropdown', "Sort by ", "")
  

  $('#per_page-form').hide();
  $('#per_page-dropdown').show();
  Blacklight.update_css_dropdown('#per_page-dropdown', '', '')



});
    })(jQuery);
