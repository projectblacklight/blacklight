$(function(){
	var bl = new Blacklight();
});

$(document).ready(function() {
  // adds classes for zebra striping table rows
  $('table.zebra tr:even').addClass('zebra_stripe');
  $('ul.zebra li:even').addClass('zebra_stripe');
});

/*************  
 * Facet more dialog. Uses JQuery UI Dialog. Use crazy closure technique. 
 * http://docs.jquery.com/UI/Dialog
 */
$(document).ready(function() {
    
    
     //Make sure more facet lists loaded in this dialog have
    //ajaxy behavior added to next/prev/sort                    
    function addBehaviorToMoreFacetDialog(dialog) {
      var dialog = $(dialog)
      
      // Remove first header from loaded content, and make it a dialog
      // title instead
      var heading = dialog.find("h1, h2, h3, h4, h5, h6").eq(0).remove();
      dialog.dialog("option", "title", heading.text());
          
      
      // Make next/prev/sort links load ajaxy
      dialog.find(".next_link a, .prev_link a, .sort_options a").click( function() {                   
          dialog.load( this.href, 
              function() {  
                addBehaviorToMoreFacetDialog(dialog);                
              }
          );
          //don't follow original href
          return false;
      });
    }

    function positionDialog(dialog) {
      dialog = $(dialog);
      
      dialog.dialog("option", "height", $(window).height()-125);
      dialog.dialog("option", "width", Math.max(  ($(window).width() /2), 45));
      dialog.dialog("option", "position", ['center', 75]);
      
      dialog.dialog("open").dialog("moveToTop");
    }
    

    $(".more_facets_link a").each(function() {
      //We use each to let us make a Dialog object for each
      //a, tied to that a, through the miracle of closures. the second
      // arg to 'bind' is used to make sure the event handler gets it's
      // own dialog. 
      var more_facets_dialog = "empty";
      
      $(this).click( function() {     
        //lazy create of dialog
        if ( more_facets_dialog == "empty") {
          more_facets_dialog = $('<div class="more_facets_dialog"></div>').dialog({ autoOpen: false});          
        }
        // Load the original URL on the link into the dialog associated
        // with it. Rails app will give us an appropriate partial.
        // pull dialog title out of first heading in contents. 
        more_facets_dialog.load( this.href , function() {
          addBehaviorToMoreFacetDialog(more_facets_dialog);
        });
                
        positionDialog(more_facets_dialog);                
                
        return false; // do not execute default href visit
      });
      
    });
});




