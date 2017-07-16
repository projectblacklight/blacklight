(function($) {
  Blacklight.onLoad(function() {
    // when clicking on a link that toggles the collapsing behavior, don't do anything
    // with the hash or the page could jump around.
    $(document).on('click', 'a[data-toggle=collapse][href="#"], [data-toggle=collapse] a[href="#"]', function(event) {
      event.preventDefault();
    });
  });
})(jQuery);
