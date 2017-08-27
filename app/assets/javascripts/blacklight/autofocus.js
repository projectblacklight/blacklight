//= require blacklight/core
(function($) {
  Blacklight.doSearchAutofocusFallback = function() {
    if (typeof Modernizer != "undefined") {
      if (Modernizr.autofocus) {
        return;
      }
    }

    $('input[autofocus]').focus();
  }

  Blacklight.onLoad(function() {
    Blacklight.doSearchAutofocusFallback();
  });
})(jQuery);