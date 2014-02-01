## Release Notes
Bug fixes include:

- #529 Responsive facet collapsing is not JS degradable
- #528 Reset "page" param on "per_page" change

And some minor feature enhancements, highlights include:
- #523 Pass the document object into helper methods so local overrides can make rendering decisions based on the current document
- #522 Make it easier to add custom SolrField fields in the Blacklight config
- add a #blacklight_solr accessor (intended to replace the global Blacklight.solr)
- a French locale translation for Blacklight (thanks @biblimathieu!)

There's a handful of Rails 4 deprecation warnings and improvements that still need to happen, but this release fixed all major blockers and relaxes the Rails version dependency.

## Upgrade Guide

No known issues.