(function($) {
    // adds classes for zebra striping table rows
    Blacklight.do_zebra_stripe = function() {  
      $(Blacklight.do_zebra_stripe.selector).addClass('zebra_stripe');        
    };
    Blacklight.do_zebra_stripe.selector = "table.zebra tr:even, ul.zebra li:even"; 
    
 
    })(jQuery);
