/*global Blacklight */

(function($) {
  'use strict';
  
  Blacklight.doResizeFacetLabelsAndCounts = function() {
    // adjust width of facet columns to fit their contents
    function longer (a,b){ return b.textContent.length - a.textContent.length; }

    $('ul.facet-values, ul.pivot-facet').each(function(){
      var longest = $(this).find('span.facet-count').sort(longer).first();
      var clone = longest.clone()
        .css('visibility','hidden').css('width', 'auto');
      $('body').append(clone);
      $(this).find('.facet-count').first().width(clone.width());
      clone.remove();
    });
  };

  Blacklight.onLoad(function() {
    Blacklight.doResizeFacetLabelsAndCounts();
  });
})(jQuery);
