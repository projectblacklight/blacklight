//= require blacklight/core
(function($) {
  Blacklight.do_lightbox_dialog = function() {    
    $("a.lightboxLink").on('click', function() {
      Blacklight.do_lightbox_dialog.modal().ajaxyDialog({
        remote: $(this).attr('href'), 
        extractHeader: function(body) { return body.find(':header').first().detach().html(); }
      });
    return false;
    });
  };

  Blacklight.do_lightbox_dialog.modal = function() {
    var existing = $("#reusableModalDialog");
    if ( existing.size() > 0) {
      existing.modal('hide');
      existing.remove();
    }
  
    //single shared element for modal dialogs      
    var requestDialog = $('<div id="reusableModalDialog" class="modal hide"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button><h3></h3></div><div class="modal-body"></div><div class="modal-footer"></div></div>').appendTo('body');
    return requestDialog;             
  };

  $(document).ready(function() {
    Blacklight.do_lightbox_dialog();  
  });
})(jQuery);
