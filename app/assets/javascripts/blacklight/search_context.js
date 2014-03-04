//= require blacklight/core
(function($) {
  Blacklight.do_search_context_behavior = function() {
      function track(event) {
        this.href = this.getAttribute('data-context-href');
        this.setAttribute('data-method', 'post');
        if(event.metaKey || event.ctrlKey) {
          this.setAttribute('target', '_blank');
        };
      }

      $('a[data-context-href]').on('click', track);
    };  
Blacklight.onLoad(function() {
  Blacklight.do_search_context_behavior();  
});
})(jQuery);
