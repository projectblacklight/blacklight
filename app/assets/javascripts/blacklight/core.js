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
    },

    listeners: function () {
      var listeners = [];
      if (Turbolinks && Turbolinks.supported) {
        // Turbolinks 5
        if (Turbolinks.BrowserAdapter) {
          listeners.push('turbolinks:load');
        } else {
          // Turbolinks < 5
          listeners.push('page:load', 'ready');
        }
      } else {
        listeners.push('ready');
      }

      return listeners.join(' ');
    }
  };
}();

// turbolinks triggers page:load events on page transition
// If app isn't using turbolinks, this event will never be triggered, no prob. 
$(document).on(Blacklight.listeners(), function() {
  Blacklight.activate();  
});


