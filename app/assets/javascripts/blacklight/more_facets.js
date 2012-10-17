//= require blacklight/core
(function($) {
  Blacklight.do_more_facets_behavior = function () {
    $( Blacklight.do_more_facets_behavior.selector ).on('click', function() {
      Blacklight.do_more_facets_behavior.modal().ajaxyDialog({
    	  remote: $(this).attr('href'),
        chainAjaxySelector: "a.btn", 
        extractHeader: function(body) { return body.find(':header').first().detach().html(); },
        extractFooter: function(body) { return body.find('.facet_pagination').detach().first(); }
      });
    return false;
  });
  };
    
  Blacklight.do_more_facets_behavior.selector = "a.more_facets_link";
    
  Blacklight.do_more_facets_behavior.modal = function() {
    var existing = $("#reusableModalDialog");
    if ( existing.size() > 0) {
      existing.modal('hide');
      existing.remove();
    }
  
    //single shared element for modal dialogs      
    var requestDialog = $('<div id="reusableModalDialog" class="modal hide fade"><div class="modal-header"><button type="button" class="close" data-dismiss="modal" aria-hidden="true">&times;</button><h3></h3></div><div class="modal-body"></div><div class="modal-footer"></div></div>').appendTo('body');
    return requestDialog;             
  };

$(document).ready(function() {
  Blacklight.do_more_facets_behavior();  
});
})(jQuery);
