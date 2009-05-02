$(document).ready(function() {
  var lightboxContent = $('#lightboxContent');
  var lightboxContainer = $('#lightboxContainer');
  var citeLink = $('#citeLink');
  var closeLink = $('#closeLightBox');
  if(lightboxContainer.css("display") != "none") {
    lightboxContent.toggle();
    lightboxContainer.toggle();
  }
  // attach the toggle behavior to the h3 tag
  citeLink.click(function(){
    // toggle the next ul sibling
    lightboxContainer.toggle();
    lightboxContent.toggle();
    return false;
  });
  closeLink.click(function(){
    // toggle the next ul sibling
    lightboxContainer.toggle();
    lightboxContent.toggle();
    return false;
  });
});