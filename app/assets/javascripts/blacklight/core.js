Blacklight = function() {
  var buffer = new Array;
  return {
    onLoad: function(func) {
      buffer.push(func);
    },

    activate: function() {
      for(var i = 0; i < buffer.length; i++) {
        buffer[i].call();
      }
    }
  }
}();

// turbolinks triggers page:load events on page transition
// If app isn't using turbolinks, this event will never be triggered, no prob. 
$(document).on('page:load', function() {
  Blacklight.activate();  
});

$(document).ready(function() {
  Blacklight.activate();  
});

