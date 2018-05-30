(function($) {
  Blacklight.doSearchAutofocusFallback = function() {
    if (typeof Blacklight.do_search_autofocus_fallback == 'function') {
      console.warn("do_search_autofocus_fallback is deprecated. Use doSearchAutofocusFallback instead.");
      return Blacklight.do_search_autofocus_fallback();
    }
    if (typeof Modernizer != 'undefined') {
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
