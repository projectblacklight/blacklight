/*global Blacklight */

'use strict';

Blacklight.onLoad(function() {
  // When we click the stretched-links
  document.querySelectorAll('.facet-field-heading > .stretched-link').forEach(function(elem){
    elem.addEventListener('click', function(e) { e.preventDefault() })
  })
})
