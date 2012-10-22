//= require blacklight/core
(function($) {
//add ajaxy dialogs to certain links, using the ajaxyDialog widget.
    Blacklight.do_more_facets_behavior = function () {
      $( Blacklight.do_more_facets_behavior.selector ).ajaxyDialog({
          width: $(window).width() / 2,  
          position: ['center', 50],
          chainAjaxySelector: "a.next_page, a.prev_page, a.sort_change"        
      });
    };
    Blacklight.do_more_facets_behavior.selector = "a.more_facets_link";
    
$(document).ready(function() {
  Blacklight.do_more_facets_behavior();  
});
})(jQuery);
