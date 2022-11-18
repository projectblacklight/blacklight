const Blacklight = function() {
  const buffer = new Array;
  return {
    onLoad: function(func) {
      buffer.push(func);
    },

    activate: function() {
      for(let i = 0; i < buffer.length; i++) {
        buffer[i].call();
      }
    },

    listeners: function () {
      const listeners = [];
      if (typeof Turbo !== 'undefined') {
        listeners.push('turbo:load', 'turbo:frame-load');
      } else if (typeof Turbolinks !== 'undefined' && Turbolinks.supported) {
        // Turbolinks 5
        if (Turbolinks.BrowserAdapter) {
          listeners.push('turbolinks:load');
        } else {
          // Turbolinks < 5
          listeners.push('page:load', 'DOMContentLoaded');
        }
      } else {
        listeners.push('DOMContentLoaded');
      }

      return listeners;
    }
  };
}();

// turbolinks triggers page:load events on page transition
// If app isn't using turbolinks, this event will never be triggered, no prob.
Blacklight.listeners().forEach(function(listener) {
  document.addEventListener(listener, function() {
    Blacklight.activate()
  })
})

Blacklight.onLoad(function () {
  const elem = document.querySelector('.no-js');

  // The "no-js" class may already have been removed because this function is
  // run on every turbo:load event, in that case, it won't find an element.
  if (!elem) return;

  elem.classList.remove('no-js')
  elem.classList.add('js')
})


export default Blacklight
