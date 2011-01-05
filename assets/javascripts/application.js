$(function(){
	var bl = new Blacklight();
});




$(document).ready(function() {
  // adds classes for zebra striping table rows
  $('table.zebra tr:even').addClass('zebra_stripe');
  $('ul.zebra li:even').addClass('zebra_stripe');
    
    
  /* function for adding items to your folder with Ajax */
    
    
	// each form for adding things into the folder.
	$("form.addFolder, form.deleteFolder").each(function() {
		var form = $(this);
    // We wrap the control on the folder page w/ a special element classed so we know not to
		// attach the jQuery function.  The reason is we want the solr response to refresh so that
		// pagination as properly udpated.
		if(form.parent(".in_folder").length == 0){
			form.submit(function(){
				$.post(form.attr("action") + '?id=' + form.children("input[name=id]").attr("value"), function(data) {
					var title = form.attr("title");
					var folder_num, notice_text, new_form_action, new_button_text
					if(form.attr("action") == "/folder/destroy") {
						folder_num = parseInt($("#folder_number").text()) - 1;
						notice_text = title + " removed from your folder."
						new_form_action = "/folder";
						new_button_text = "Add to folder"
					}else{
						folder_num = parseInt($("#folder_number").text()) + 1
						notice_text = title + " added to your folder.";
						new_form_action = "/folder/destroy";
						new_button_text = "Remove from folder";
					}
				  $("#folder_number").text(folder_num);
					form.attr("action",new_form_action);
					form.children("input[type=submit]").attr("value",new_button_text);
				}, "json");
				return false;
			});
	  }
	});	
	//end folder actions
	
	//add ajaxy dialogs to certain links, using the ajaxyDialog widget. 
    $("a.more_facets_link").ajaxyDialog({
        width: $(window).width() / 2,  
        chainAjaxySelector: "a.next_page, a.prev_page, a.sort_change"        
    });    
    $("a.lightboxLink").ajaxyDialog({
        chainAjaxySelector: false
    });
    //But make the librarian link wider than 300px default. 
    $('a.lightboxLink#librarianLink').ajaxyDialog("option", "width", 650);
    //And the email one too needs to be wider to fit the textarea
    $("a.lightboxLink#emailLink").ajaxyDialog("option", "width", 500);
    
});

      
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
                  closeDialogSelector: "a.dialog-close",
                  beforeDisplay: jQuery.noop
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
                      success: function(resp, status) {
                        self._loadToDialog(resp);
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
                      success: function(resp, status) {
                        self._loadToDialog(resp);
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

