## Release Notes
### 4.4.0


Features
- [#598](https://github.com/projectblacklight/blacklight/issues/598) Show thumbnails (if available) for documents in search results
- [#594](https://github.com/projectblacklight/blacklight/issues/594) Provide Blacklight configuration support for linking field values to facets
- [#589](https://github.com/projectblacklight/blacklight/issues/589) Support Rails 4.x-style turbolinks (Blacklight-provided javascript should be loaded on document ready or the page:load  event)
- [#588](https://github.com/projectblacklight/blacklight/issues/588) Provide an (experimental) JSON API for search and show
- [#577](https://github.com/projectblacklight/blacklight/issues/477) Add Solr Field Collapsing feature, if the Solr response includes a grouped element.

Bug Fixes
- [#640](https://github.com/projectblacklight/blacklight/issues/640) Fix the solr query Blacklight generates when the query contains Solr "local parameters" containing digits (e.g. $pf2_value)
- [#590](https://github.com/projectblacklight/blacklight/issues/590) Fix transferring unregistered guest user bookmarks to a newly registered user
- [#587](https://github.com/projectblacklight/blacklight/issues/587) Fix Zotero support, where ampersands in the context object were being double escaped
- [#534](https://github.com/projectblacklight/blacklight/issues/534) Blacklight::CatalogHelperBehavior#paginate_params values of first_page? and last_page? incorrectly set?
- [#525](https://github.com/projectblacklight/blacklight/issues/525) Add i18n support to Bookmarks javascript replacement
- [#585](https://github.com/projectblacklight/blacklight/issues/585) Add keyboard accessibility to the facet expanders
- [#563](https://github.com/projectblacklight/blacklight/issues/563) Login page should have focus in the email field, not the search field.

Other Improvements
- [#600](https://github.com/projectblacklight/blacklight/issues/600) Decomposing blacklight generator
- [#599](https://github.com/projectblacklight/blacklight/issues/599) Improving speed of blacklight generator
- [#597](https://github.com/projectblacklight/blacklight/issues/597) Rewrite document_counter logic in header
- [#596](https://github.com/projectblacklight/blacklight/issues/596) Don't generate devise views by default
- [#595](https://github.com/projectblacklight/blacklight/issues/595) Support kaminari pagination helpers in Blacklight::SolrResponse (kaminari can now work with our SolrResponse objects natively).
- [#591](https://github.com/projectblacklight/blacklight/issues/591) Remove cucumber. All features have been ported to rspec feature tests.
- [#584](https://github.com/projectblacklight/blacklight/issues/584) Move onload_text out of layouts/blacklight.html.erb
- [#515](https://github.com/projectblacklight/blacklight/issues/515) Ensure we run bundle install after generating bootstrap-sass into the Gemfile
- Update lightbox_dialog.js - Adding an event for DOM change when modal is already shown
- [#607](https://github.com/projectblacklight/blacklight/issues/607) Refactor catalog#email and catalog#sms methods
- [#609](https://github.com/projectblacklight/blacklight/issues/609) The solr facet :ex local parameter should work with pivot and facet
field configurations.
- Convert some bare strings to i18n strings
- [#608](https://github.com/projectblacklight/blacklight/issues/608) Use ActiveRecord query methods in Blacklight::User mixin

[[Changes|https://github.com/projectblacklight/blacklight/compare/v4.3.0...v4.4.0]]

## Upgrade Guide

If you've overridden the `catalog/sms.html.erb` template or `RecordMailer#sms` action (e.g. to add custom SMS provider mappings), you should look at the changes in [this patch](https://github.com/projectblacklight/blacklight/pull/607), which moved the mappings and validation into the controller.