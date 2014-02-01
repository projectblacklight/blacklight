## Release Notes
### 4.3.0
Bug fixes include:

- #556 	check that a highlight field exists before trying to render it.
- #561 	Redirect to home page on a missing document 
- #569 	Applies header style to `#header-navbar-fixed-top .brand` in order to avoid trumping other Bootstrap navbars.
- use `#facet_configuration_for_field` to render search history constraints for consistency and configuration-independence

Other changes:
- deprecate `#sidebar_items`, and stop populating it with content.
- provide a `SOLR_URL` ENV variable to set the location of the development solr core
- fix Rails 4-related deprecation warnings

[[Changes|https://github.com/projectblacklight/blacklight/compare/v4.2.2...v4.3.0]]

## Upgrade Guide

Application overrides that used the CSS selector `.navbar .brand` to change the navbar styling should use `#header-navbar-fixed-top .brand` instead.

Applications that used content from `#sidebar_items` must populate that content themselves (by rendering it directly in their partial, or in some other application-specific way). 