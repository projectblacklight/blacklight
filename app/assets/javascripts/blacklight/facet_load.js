//= require blacklight/core
(function($) {
  Blacklight.onLoad(function() {
    // adjust width of facet columns to fit their contents
    $('ul.facet-values, ul.pivot-facet').map(function(){
      function longer (a,c){return a.textContent.length>c.textContent.length?a:c;}
      var longest = Array.prototype.reduce.apply($(this).find('.facet-count span'),[longer]);
      var clone = $(longest).clone().css('visibility','hidden');
      $('body').append(clone);
      $(this).find('.facet-count').first().width(clone.width());
      clone.remove();
    });
  });
})(jQuery);
