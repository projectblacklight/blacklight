(function($) {
  Blacklight.do_search_context_behavior = function() {
      $('a[data-counter]').click(function(event) {
      var f = document.createElement('form'); f.style.display = 'none'; 
      this.parentNode.appendChild(f); 
      f.method = 'POST'; 
      f.action = $(this).attr('href');
      if(event.metaKey || event.ctrlKey){f.target = '_blank';};
      var d = document.createElement('input'); d.setAttribute('type', 'hidden'); 
      d.setAttribute('name', 'counter'); d.setAttribute('value', $(this).data('counter')); f.appendChild(d);
      var m = document.createElement('input'); m.setAttribute('type', 'hidden'); 
      m.setAttribute('name', '_method'); m.setAttribute('value', 'put'); f.appendChild(m);
      var m = document.createElement('input'); m.setAttribute('type', 'hidden'); 
      m.setAttribute('name', $('meta[name="csrf-param"]').attr('content')); m.setAttribute('value', $('meta[name="csrf-token"]').attr('content')); f.appendChild(m);

      f.submit();
        
      return false;
      });

    };  
$(document).ready(function() {
  Blacklight.do_search_context_behavior();  
});
})(jQuery);
