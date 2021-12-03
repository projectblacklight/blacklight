import Bloodhound from 'typeahead.js/dist/bloodhound.js'
import Blacklight from './core'

const Autocomplete = (() => {
  Blacklight.onLoad(function() {
    'use strict';

    document.querySelectorAll('[data-autocomplete-enabled="true"]').forEach((el) {
      if(el.classList.contains('tt-hint')) {
        return;
      }
      var suggestUrl = el.dataset.autocompletePath;

      var terms = new Bloodhound({
        datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
        queryTokenizer: Bloodhound.tokenizers.whitespace,
        remote: {
          url: suggestUrl + '?q=%QUERY',
          wildcard: '%QUERY'
        }
      });

      terms.initialize();

      $(el).typeahead({
        hint: true,
        highlight: true,
        minLength: 2
      },
      {
        name: 'terms',
        displayKey: 'term',
        source: terms.ttAdapter()
      });
    });
  });
})();

export default Autocomplete
