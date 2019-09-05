/*global Blacklight */

'use strict';

Blacklight.doResizeFacetLabelsAndCounts = function() {
  // adjust width of facet columns to fit their contents
  function longer (a,b) { return b.textContent.length - a.textContent.length }

  document.querySelectorAll('.facet-values, .pivot-facet').forEach(function(elem){
    const nodes = elem.querySelectorAll('.facet-count')
    // TODO: when we drop ie11 support, this can become the spread operator:
    const longest = Array.from(nodes).sort(longer)[0]
    if (longest && longest.textContent) {
      const width = longest.textContent.length + 1 + 'ch'
      elem.querySelector('.facet-count').style.width = width
    }
  })
}

Blacklight.onLoad(function() {
  Blacklight.doResizeFacetLabelsAndCounts()
})
