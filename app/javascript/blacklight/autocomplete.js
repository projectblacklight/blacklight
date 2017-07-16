/*global Bloodhound */
import Bloodhound from 'typeahead.js/dist/bloodhound.js'

Blacklight.onLoad(function() {
  'use strict';

  $('[data-autocomplete-enabled="true"]').each(function() {
    var $el = $(this);
    if($el.hasClass('tt-hint')) {
      return;
    }
    var suggestUrl = $el.data().autocompletePath;

    var terms = new Bloodhound({
      datumTokenizer: Bloodhound.tokenizers.obj.whitespace('value'),
      queryTokenizer: Bloodhound.tokenizers.whitespace,
      remote: {
        url: suggestUrl + '?q=%QUERY',
        wildcard: '%QUERY'
      }
    });

    terms.initialize();

    $el.typeahead({
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
