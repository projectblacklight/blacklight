//= require blacklight/core
(function($) {
Blacklight.do_facet_expand_contract_behavior = function() {
      $( Blacklight.do_facet_expand_contract_behavior.selector ).each (
          Blacklight.facet_expand_contract
       );
    }
    Blacklight.do_facet_expand_contract_behavior.selector = '#facets h3';
    	    
	    /* Behavior that makes facet limit headings in sidebar expand/contract
	       their contents. This is kind of fragile code targeted specifically
	       at how we currently render facet HTML, which is why I put it in a function
	       on Blacklight instead of in a jquery plugin. Perhaps in the future this
	       could/should be expanded to a general purpose jquery plugin -- or
	       we should just use one of the existing ones for expand/contract? */
     Blacklight.facet_expand_contract = function() {
       $(this).next("ul, div").each(function(){
           var f_content = $(this);
           $(f_content).prev('h3').addClass('twiddle');
           // find all f_content's that don't have any span descendants with a class of "selected"
           if($('span.selected', f_content).length == 0){
             // hide it
             f_content.hide();
           } else {
             $(this).prev('h3').addClass('twiddle-open');
           }

           // attach the toggle behavior to the h3 tag
           $('h5', f_content.parent()).click(function(){
               // toggle the content
               $(this).toggleClass('twiddle-open');
               $(f_content).slideToggle();
           });
           $('a', f_content.parent()).click(function(){
               // toggle the content
               $(this).toggleClass('twiddle-open');
               $(f_content).slideToggle();
           });
       });
   };
$(document).ready(function() {
  Blacklight.do_facet_expand_contract_behavior();  
});
})(jQuery);

