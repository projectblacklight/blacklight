/*global Blacklight */

(function($) {
  'use strict';
  
  Blacklight.doResizeFacetLabelsAndCounts = function() {
    // adjust width of facet columns to fit their contents
    function longer (a,b){ return b.textContent.length - a.textContent.length; }

    $('ul.facet-values, ul.pivot-facet').each(function(){
      var longest = $(this).find('span.facet-count').sort(longer)[0];
      
      if (longest && longest.textContent) {
        var width = longest.textContent.length + 1 + 'ch';
        $(this).find('.facet-count').first().width(width);
      }
    });
  };

  Blacklight.onLoad(function() {
    Blacklight.doResizeFacetLabelsAndCounts();
  });
})(jQuery);
