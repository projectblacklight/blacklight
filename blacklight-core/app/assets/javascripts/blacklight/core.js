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

if (typeof Turbolinks !== "undefined") {
  $(document).on('page:load', function() {
    Blacklight.activate();  
  });
}
$(document).ready(function() {
  Blacklight.activate();  
});

