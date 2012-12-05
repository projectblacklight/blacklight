//= require blacklight/core
Blacklight.setup_modal = function(link_selector, form_selector, launch_modal) {
    $(link_selector).click(function(e) {
      link = $(this)
      
      e.preventDefault();

      var jqxhr = $.ajax({
        url: link.attr('href'),
        dataType: 'script'
      });

      jqxhr.always( function (data) {
            $('#ajax-modal').html(data.responseText);
            Blacklight.setup_modal('.modal-footer a', '#ajax-modal form.ajax_form', false);

            if (launch_modal) {
              $('#ajax-modal').modal();
            }
            Blacklight.check_close_ajax_modal();
      });
    });


    $(form_selector).submit(function(e) {
      var jqxhr = $.ajax({
        url: $(this).attr('action'),
        data: $(this).serialize(),
        type: 'POST',
        dataType: 'script'
     });


     jqxhr.always (function (data) {
          $('#ajax-modal').html(data.responseText);
          Blacklight.setup_modal('#ajax-modal .ajax_reload_link', '#ajax-modal form.ajax_form', false);
          Blacklight.check_close_ajax_modal();
     });


      return false;


    });
};

Blacklight.check_close_ajax_modal = function() {
  if ($('#ajax-modal span.ajax-close-modal').length) {
    modal_flashes = $('#ajax-modal .flash_messages');

    main_flashes = $('#main-flashes .flash_messages:nth-of-type(1)');
    $('#ajax-modal *[data-dismiss="modal"]:nth-of-type(1)').trigger('click');
    main_flashes.append(modal_flashes);
    modal_flashes.fadeIn(500);



  }

}

$(document).ready( function() {
  Blacklight.setup_modal("a.lightboxLink,a.more_facets_link,.ajax_modal_launch", "#ajax-modal form.ajax_form", true);
});
