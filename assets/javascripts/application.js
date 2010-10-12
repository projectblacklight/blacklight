$(function(){
	var bl = new Blacklight();
});

$(document).ready(function() {
  // adds classes for zebra striping table rows
  $('table.zebra tr:even').addClass('zebra_stripe');
  $('ul.zebra li:even').addClass('zebra_stripe');
});

// function for adding items to your folder with Ajax
$(document).ready(function() {
	// each form for adding things into the folder.
	$("form.addFolder").each(function() {
		// when the form is submitted
		$(this).submit(function() {
			var form = $(this);
			// make a post request to add the item to the users folder items
			$.post('/folder?id=' + form.children("input[name=id]").attr("value"), function(data) {
				// toggle the next element w/ a folder_note class
			  form.next(".folder_note").toggle();
			  // remove the form from the DOM
			  form.remove();
			  // increase the number of items in the folder 
			  $("#folder_number").text(parseInt($("#folder_number").text()) + 1);
			  // add in a fading notice that the item was added, then remove it from the DOM
			  top = parseInt($(window).scrollTop()) + 100;
				notice = "<div id='fading_notice' class='notice' style='position:absolute;top:" + top + "px;left:40%'>" + form.children("input[name=title]").attr("value") + " added to your folder.</div>";
			  $("body").append(notice);
			  $("#fading_notice").fadeOut(3500, function(){
				  $("#fading_notice").remove();
			  });
			});
			// do not submit the form
			return false;
		});
	});
});

/*************  
 * Facet more dialog. Uses JQuery UI Dialog. Use crazy closure technique. 
 * http://docs.jquery.com/UI/Dialog
 */
 
jQuery(document).ready(function($) {    
    
    //Make sure more facet lists loaded in this dialog have
    //ajaxy behavior added to next/prev/sort                    
    function addBehaviorToMoreFacetDialog(dialog) {
      var dialog = $(dialog)      
      
      // Make next/prev/sort links load ajaxy
      dialog.find("a.next_page, a.prev_page, a.sort_change").click( function() {     
          $("body").css("cursor", "progress");
          dialog.load( this.href, 
              function() {  
                addBehaviorToMoreFacetDialog(dialog);
                $("body").css("cursor", "auto");                
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
    

    $("a.more_facets_link,a.lightboxLink").each(function() {
      //We use each to let us make a Dialog object for each
      //a, tied to that a, through the miracle of closures. the second
      // arg to 'bind' is used to make sure the event handler gets it's
      // own dialog. 
      var dialog_box = "empty";
      var link = $(this);
      $(this).click( function() {     
        //lazy create of dialog
        if ( dialog_box == "empty") {
          dialog_box = $('<div class="dialog_box"></div>').dialog({ autoOpen: false});          
        }
        // Load the original URL on the link into the dialog associated
        // with it. Rails app will give us an appropriate partial.
        // pull dialog title out of first heading in contents. 
        $("body").css("cursor", "progress");
        dialog_box.load( this.href , function() {
	        if(link.attr("class") == "more_facets_link"){
            addBehaviorToMoreFacetDialog(dialog_box);
				  }
				  // Remove first header from loaded content, and make it a dialog
		      // title instead
		      var heading = dialog_box.find("h1, h2, h3, h4, h5, h6").eq(0).remove();
		      dialog_box.dialog("option", "title", heading.text());
          $("body").css("cursor", "auto");
        });

        positionDialog(dialog_box);                
                
        return false; // do not execute default href visit
      });
      
    });
});



