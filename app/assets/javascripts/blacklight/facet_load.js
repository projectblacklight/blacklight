/*global Blacklight */

(function($) {
  Blacklight.do_resize_facet_labels_and_counts = function() {
    // adjust width of facet columns to fit their contents
    function longer (a,b){ return b.textContent.length - a.textContent.length; }

    $('ul.facet-values, ul.pivot-facet').map(function(){
      var longest = $(this).find('span.facet-count').sort(longer).first();
      var clone = longest.clone().css('visibility','hidden').css('width', 'auto');
      $('body').append(clone);
      $(this).find('.facet-count').first().width(clone.width());
      clone.remove();
    });
  };

  Blacklight.onLoad(function() {
    Blacklight.do_resize_facet_labels_and_counts();
  });
})(jQuery);
