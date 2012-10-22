//= require blacklight/core
(function($) {
Blacklight.do_lightbox_dialog = function() {    
      $("a.lightboxLink").ajaxyDialog({
          chainAjaxySelector: false,
          position: ['center', 50]
      });
      //But make the librarian link wider than 300px default. 
      $('a.lightboxLink#librarianLink').ajaxyDialog("option", "width", 650);
      //And the email one too needs to be wider to fit the textarea
      $("a.lightboxLink#emailLink").ajaxyDialog("option", "width", 500);
    };
$(document).ready(function() {
  Blacklight.do_lightbox_dialog();  
});
})(jQuery);
