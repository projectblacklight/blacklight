const Core = function() {
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
      } else {
        listeners.push('DOMContentLoaded');
      }

      return listeners;
    }
  };
}();

// turbo triggers turbo:load events on page transition
// If app isn't using turbo, this event will never be triggered, no prob.
Core.listeners().forEach(function(listener) {
  document.addEventListener(listener, function() {
    Core.activate()
  })
})

Core.onLoad(function () {
  const elem = document.querySelector('.no-js');

  // The "no-js" class may already have been removed because this function is
  // run on every turbo:load event, in that case, it won't find an element.
  if (!elem) return;

  elem.classList.remove('no-js')
  elem.classList.add('js')
})


export default Core
