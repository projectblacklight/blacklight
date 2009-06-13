// To create a lightbox, insert the element into a view, give it a class of .lightboxContent and an ID.
// To create the link to activate the lightbox, give the link a class of .lightboxLink and name it
// the same thing as your lightboxContent element ID.
// You will need a close link in the lightbox.  You can create that by making a link that has class of 
// .lightboxLink and name it the same thing as your lightboxContent ID
// Note: The Open and close links are pretty much identical.
$(document).ready(function() {
  var closeLink = $('.closeLightBox');
  var lightboxContainer = $('#lightboxContainer');
    $(".lightboxLink").each(function(){
        $(this).click(function(){
            var lbelem = $("#" + $(this).attr("name"));
            lightboxContainer.toggle();
            lbelem.toggle();
            return false;
        });
    });
});