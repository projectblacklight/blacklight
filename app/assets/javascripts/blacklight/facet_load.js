/*global Blacklight */

(function($) {
  Blacklight.onLoad(function() {
    // adjust width of facet columns to fit their contents
    function longer (a,b){ return b.textContent.length - a.textContent.length; }
    $('ul.facet-values, ul.pivot-facet').map(function(){
      var longest = $(this).find('.facet-count span').sort(longer).first();
      var clone = longest.clone().css('visibility','hidden');
      $('body').append(clone);
      $(this).find('.facet-count').first().width(clone.width());
      clone.remove();
    });
  });
})(jQuery);
