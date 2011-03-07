/* Blacklight has a Javascript setup meant to support local disabling, 
  modification, and use of Blacklight behaviors. 
  
  There is a global Blacklight object, available to your local JS. 
  
  Individual logic to apply JS behaviors to particular elements is 
  stored in functions on that Blacklight object. 
  
  The actual behaviors themselves are implemented as JQuery plugins, 
  JQuery-UI widgets (a special kind of JQuery plugin), or in some cases
  just as logic in the Blacklight global object. 
  
  All of these things can be modified by your local JS code -- these functions
  are all set up on js load, and only called on document ready, so do your
  modifications just on js load, and they'll be made by the time document ready
  comes along. 
  
  Examples, in your application's own JS:
  
    Change what items zebra_striping gets applied to:
    
        Blacklight.do_zebra_stripe.selector = ".my_class .even";
        //Or even add on to existing:
        Blacklight.do_zebra_stripe.selector = Blacklight.do_zebra_stripe.selector + " .my_class .even";
      
    Turn off adding of behavior to facet 'more' links, using a no-op function:
    
        Blacklight.do_more_facets_behavior = function() {};
        
    Change the implementation of facet 'more' link behavior to use entirely
    different JS. 
    
        Blacklight.do_more_facets_behavior = function() {
          $(Blacklight.do_more_facets_behavior.selector).each(function() {
            //my own thing!
          });
        };
*/

Blacklight = {};


$(document).ready(function() {
  Blacklight.do_zebra_stripe();  
  
  Blacklight.do_select_submit();
  
  Blacklight.do_more_facets_behavior();
  
  Blacklight.do_lightbox_dialog();
  
  Blacklight.do_bookmark_toggle_behavior();
  
  Blacklight.do_folder_toggle_behavior();       
  
  Blacklight.do_facet_expand_contract_behavior();
});



//Note all of these definitions are NOT in document ready, they get defined on
//page load, and later called on document ready. 
(function($) {
    
    // adds classes for zebra striping table rows
    Blacklight.do_zebra_stripe = function() {  
      $(Blacklight.do_zebra_stripe.selector).addClass('zebra_stripe');        
    };
    Blacklight.do_zebra_stripe.selector = "table.zebra tr:even, ul.zebra li:even"; 
    
    //add ajaxy dialogs to certain links, using the ajaxyDialog widget.
    Blacklight.do_more_facets_behavior = function () {
      $( Blacklight.do_more_facets_behavior.selector ).ajaxyDialog({
          width: $(window).width() / 2,  
          chainAjaxySelector: "a.next_page, a.prev_page, a.sort_change"        
      });
    };
    Blacklight.do_more_facets_behavior.selector = "a.more_facets_link";
    
    // Used for sort-by and per-page controls, hide the submit button
    // and make the select auto-submit
    Blacklight.do_select_submit = function() {
      $(Blacklight.do_select_submit.selector).each(function() {
          var select = $(this);
          select.closest("form").find("input[type=submit]").hide();
          select.bind("change", function() {
              this.form.submit();
          });
      });
    };
    Blacklight.do_select_submit.selector = "form.sort select, form.per_page select";
    
    
    Blacklight.do_lightbox_dialog = function() {    
      $("a.lightboxLink").ajaxyDialog({
          chainAjaxySelector: false
      });
      //But make the librarian link wider than 300px default. 
      $('a.lightboxLink#librarianLink').ajaxyDialog("option", "width", 650);
      //And the email one too needs to be wider to fit the textarea
      $("a.lightboxLink#emailLink").ajaxyDialog("option", "width", 500);
    };
    
    //change form submit toggle to checkbox
    Blacklight.do_bookmark_toggle_behavior = function() {
      $(Blacklight.do_bookmark_toggle_behavior.selector).bl_checkbox_submit({          
          checked_label: "In Bookmarks",
          unchecked_label: "Bookmark",
          progress_label: "Saving...",
          //css_class is added to elements added, plus used for id base
          css_class: "toggle_bookmark"    
      }); 
    };
    Blacklight.do_bookmark_toggle_behavior.selector = "form.bookmark_toggle"; 
    
    Blacklight.do_folder_toggle_behavior = function() {
      $( Blacklight.do_folder_toggle_behavior.selector ).bl_checkbox_submit({
          checked_label: "Selected",
          unchecked_label: "Select",
          css_class: "toggle_folder",
          success: function(new_state) {
            
            if (new_state) {
               $("#folder_number").text(parseInt($("#folder_number").text()) + 1);
            }
            else {
               $("#folder_number").text(parseInt($("#folder_number").text()) - 1);
            }
          }
      });
      
    };
    Blacklight.do_folder_toggle_behavior.selector = "form.folder_toggle"; 
    
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
           $('h3', f_content.parent()).click(function(){
               // toggle the content
               $(this).toggleClass('twiddle-open');
               $(f_content).slideToggle();
           });
       });
   };
    
})(jQuery);






/* A JQuery plugin (should this be implemented as a widget instead? not sure)
   that will convert a "toggle" form, with single submit button to add/remove
   something, like used for Bookmarks/Folder, into an AJAXy checkbox instead. 
   
   Apply to a form. Does require certain assumption about the form:
    1) The same form 'action' href must be used for both ADD and REMOVE
       actions, with the different being the hidden input name="_method"
       being set to "put" or "delete" -- that's the Rails method to pretend
       to be doing a certain HTTP verb. So same URL, PUT to add, DELETE
       to remove. This plugin assumes that. 
       
       Plus, the form this is applied to should provide a data-doc-id 
       attribute (HTML5-style doc-*) that contains the id/primary key
       of the object in question -- used by plugin for a unique value for
       DOM id's. 
       
   Pass in options for your class name and labels:
   $("form.something").bl_checkbox_submit({    
        checked_label: "Selected",
        unchecked_label: "Select",
        progress_label: "Saving...",
        //css_class is added to elements added, plus used for id base
        css_class: "toggle_my_kinda_form",
        success: function(after_success_check_state) {
          #optional callback
        }
   });
*/
(function($) {    
    $.fn.bl_checkbox_submit = function(arg_opts) {              
      
      this.each(function() {
        var options = $.extend({}, $.fn.bl_checkbox_submit.defaults, arg_opts);
                                  
          
        var form = $(this);
        form.children().hide();
        //We're going to use the existing form to actually send our add/removes
        //This works conveneintly because the exact same action href is used
        //for both bookmarks/$doc_id.  But let's take out the irrelevant parts
        //of the form to avoid any future confusion. 
        form.find("input[type=submit]").remove();
        
        //View needs to set data-doc-id so we know a unique value
        //for making DOM id
        var unique_id = form.attr("data-doc-id") || Math.random();
        // if form is currently using method delete to change state, 
        // then checkbox is currently checked
        var checked = (form.find("input[name=_method][value=delete]").size() != 0);
            
        var checkbox = $('<input type="checkbox">')	    
          .addClass( options.css_class )
          .attr("id", options.css_class + "_" + unique_id);	  
        var label = $('<label>')
          .addClass( options.css_class )
          .attr("for", options.css_class + '_' + unique_id)
          .attr("title", form.attr("title"));
          
          
        function update_state_for(state) {
            checkbox.attr("checked", state);
            label.toggleClass("checked", state);
            if (state) {    
               //Set the Rails hidden field that fakes an HTTP verb
               //properly for current state action. 
               form.find("input[name=_method]").val("delete");
               label.text(options.checked_label);
            } else {
               form.find("input[name=_method]").val("put");
               label.text(options.unchecked_label);
            }
          }
        
        form.append(checkbox).append(" ").append(label);
        update_state_for(checked);
        
        checkbox.click(function() {
            label.text(options.progress_label).attr("disabled", "disabled");  
            checkbox.attr("disabled", "disabled");
                            
            $.ajax({
                url: form.attr("action"),
                type: form.attr("method").toUpperCase(),
                data: form.serialize(),
                error: function() {
                   alert("Error");
                   update_state_for(checked);
                   label.removeAttr("disabled");
                   checkbox.removeAttr("disabled");
                },
                success: function(data, status, xhr) {
                  //if app isn't running at all, xhr annoyingly
                  //reports success with status 0. 
                  if (xhr.status != 0) {
                    checked = ! checked;
                    update_state_for(checked);
                    label.removeAttr("disabled");
                    checkbox.removeAttr("disabled");
                    options.success.call(form, checked);
                  } else {
                    alert("Error");
                    update_state_for(checked);
                    label.removeAttr("disabled");
                    checkbox.removeAttr("disabled");
                  }
                }
            });
            
            return false;
        }); //checkbox.click
        
        
      }); //this.each      
      return this;
    };
	
  $.fn.bl_checkbox_submit.defaults =  {
            checked_label: "",
            unchecked_label: "",
            progress_label: "Saving...",
            //css_class is added to elements added, plus used for id base
            css_class: "bl_checkbox_submit",
            success: function() {} //callback
  };
    
})(jQuery);

      
/* A widget written by jrochkind to make a link or form result in
   an in-window ajaxy dialog, instead of page load, using JQuery UI
   Dialog widget. 
      
   This widget is actually hosted at: https://github.com/jrochkind/jquery.uiExt.ajaxyDialog
   
   
   Included in this main file because I just couldn't bare to add yet
   another JS file to our app, until we figure out a good fix those too
   many JS files are serious page load speed problem. */ 

      (function($) {
          var widgetNamespace = "uiExt";
          var widgetName = "ajaxyDialog";
          
          $.widget(widgetNamespace + "." + widgetName, {
              options: {
                  extractTitleSelector: "h1, h2, h3, h4, h5",
                  chainAjaxySelector: "a:not([target]), form:not([target])",
                  closeDialogSelector: "a.dialog-close"
              },
              
              _create: function() {
                  var self = this;
                  var element = self.element[0];
                  if (element.tagName.toUpperCase() == "A") {
                    $(element).bind("click."+self.widgetName,  function(event, ui) {                        
                        self._handleClick(); 
                        return false;
                    });
                  }
                  else if (element.tagName.toUpperCase() == "FORM") {
                    $(element).bind("submit."+self.widgetName,  function(event, ui) {
                        self._handleSubmit();
                        return false;
                    });
                  }                
              },
                        
              open: function() {
                var self = this;
                var element = self.element[0];                                
                                
                if ( element.tagName.toUpperCase() == "A") {
                  self._handleClick();
                } else if (element.tagName.toUpperCase() == "FORM") {
                  self._handleSubmit();
                }
              },
              
              close: function() {
                this.dialogContainer().dialog("close"); 
              },                            
              
              _handleClick: function() {
                  var self = this;
                  var url = this.element.attr("href");
                  var requestDialog = self.dialogContainer();
            
                  $("body").css("cursor", "progress");
            
                  $.ajax({
                      url: url,
                      dataType: "html",
                      success: function(resp, status, xhr) {
                        if (xhr.status != 0) {                          
                          self._loadToDialog(resp);
                        } else {
                          //stupid jquery calling this 'success', it's
                          //network unavailable.
                          self._displayFailure(url, xhr, status); 
                        }
                      },
                      error: function(xhr, msg) {
                        self._displayFailure(url, xhr, msg); 
                      }
                  });                                
              },
              
              _handleSubmit: function() {
                  var self = this;
                  var form = self.element;
                  var actionUri = form.attr("action");
                  var serialized = form.serialize();
            
                  $("body").css("cursor", "progress");
            
                  $.ajax({
                      url: actionUri,
                      data: serialized,
                      type: form.attr("method").toUpperCase(),
                      dataType: "html",
                      success: function(resp, status, xhr) {
                        if (xhr.status != 0) {
                          self._loadToDialog(resp);
                        } else {
                          //stupid jquery calling this 'success', it's
                          //network unavailable.
                          self._displayFailure(url, xhr, status); 
                        }
                      },
                      error: function(xhr, msg) {
                        self._displayFailure(actionUri, xhr, msg); 
                      }
                  });
              },
              
              _loadToDialog: function(html_content) {     
                  var self = this;
                  var dialog = self.dialogContainer();
                  //Cheesy way to restore it to it's default options, plus
                  //our own local options, since its' a reuseable dialog.
                  //for now we insist on modal:true. 
                  dialog.dialog($.extend({}, 
                                  $.ui.dialog.prototype.options, 
                                  self.options, 
                                  {autoOpen:false, modal:true}
                                ));
                                    
                  if (self._trigger('beforeDisplay', 0, html_content) !== false) {                  
                    dialog.html( html_content );
            
                    //extract and set title
                    var title;
                    self.options.extractTitleSelector &&
                      (title = dialog.find(self.options.extractTitleSelector).first().remove().text());                  
                    title = title || 
                      self.element.attr("title")
                    title && dialog.dialog("option", "title", title);
                                
                    //Make any hyperlinks or forms ajaxified, by applying
                    //this very same plugin to em, and passing on our options.  
                    if (self.options.chainAjaxySelector) {
                      dialog.find(self.options.chainAjaxySelector).ajaxyDialog(self.options);
                    }
            
                    //Make any links marked dialog-close do so
                    if ( self.options.closeDialogSelector ) {
                      dialog.find(self.options.closeDialogSelector).unbind("click." + widgetName);
                      dialog.find(self.options.closeDialogSelector).bind("click." + widgetName, function() {
                          dialog.dialog("close");
                          return false;
                      });
                    }
            
                    dialog.dialog("open");
                  }
                  $("body").css("cursor", "auto");
              },
              
              _displayFailure: function(uri, xhr, serverMsg) {
                if (  this._trigger("error", 0, {uri:uri, xhr: xhr, serverMsg: serverMsg}) !== false) {                                                           
                      var dialog = this.dialogContainer();
                          
                      dialog.html("<div class='ui-state-error' style='padding: 1em;'><p><span style='float: left; margin-right: 0.3em;' class='ui-icon ui-icon-alert'></span>Sorry, a software error has occured.</p><p>" + uri + ": " + xhr.status + " "  + serverMsg+"</p></div>");
                      dialog.dialog("option", "title", "Sorry, an error has occured.");           
                      dialog.dialog("option", "buttons", {"OK": function() { dialog.dialog("close"); }});
                      dialog.dialog("open");
                  }           
                  $("body").css("cursor", "auto");
              },
              
              // The DOM element which has a ui dialog() called on it. 
              // Right now we insist upon modal dialogs, and re-use the same
              // <div>.dialog() for all of them. It's lazily created here.   
              // If client calls dialog("destroy") on it, no problem, it'll
              // be lazily created if it's needed again. 
              dialogContainer: function() {
                var existing = $("#reusableModalDialog");
                if ( existing.size() > 0) {
                  return existing.first();
                }
                else {
                  //single shared element for modal dialogs      
                  var requestDialog = $('<div id="reusableModalDialog" style="display:none"></div>').appendTo('body').
                      dialog({autoOpen: false}); 
                  return requestDialog;
                }
              }
              
          });
      }(jQuery));

