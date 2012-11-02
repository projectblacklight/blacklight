//= require blacklight/core
(function($) {
// Used for sort-by and per-page controls, hide the submit button
    // and make the select auto-submit
    Blacklight.bind_dropdown_submit = function(form, dropdown, auto_submit) {
        $(dropdown).find('ul.dropdown-menu a').click( function () {
          selection = $(this).attr('data-value');
          selection_key = $(this).text();

          $(dropdown).find('a.dropdown-toggle').html(selection_key + ' <b class="caret"></b>');

          $(form).find('select').val(selection);
          if (auto_submit) {
           $(form).submit();
          }

        });
      }


$(document).ready(function() {
  $('#sort-form').hide();
  $('#sort-dropdown').show();
  Blacklight.bind_dropdown_submit('#sort-form', '#sort-dropdown' , true);

  $('#per_page-form').hide();
  $('#per_page-dropdown').show();
  Blacklight.bind_dropdown_submit('#per_page-form', '#per_page-dropdown', true );

  $('.search-options-select').hide();
  $('.search-options-dropdown').show();
  Blacklight.bind_dropdown_submit('.search-query-form', '.search-box-options', false );


});
    })(jQuery);
