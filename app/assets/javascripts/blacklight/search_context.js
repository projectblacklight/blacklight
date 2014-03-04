//= require blacklight/core
(function($) {
  Blacklight.do_search_context_behavior = function() {
      function track(link) {
        link.href = link.href + "/track?counter="+ link.getAttribute('data-counter')+'&search_id='+link.getAttribute('data-search_id')
        link.setAttribute('data-method', 'post')
      }

      $('a[data-counter]').on('mousedown', function(e) {
        track(this);
      });
      $('a[data-counter]').on('keydown', function(e) {
        if(e.keyCode == 13){
          track(this);
        }
      });
    };  
Blacklight.onLoad(function() {
  Blacklight.do_search_context_behavior();  
});
})(jQuery);
