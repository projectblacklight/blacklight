# Blacklight 3.6 Release Notes And Upgrade Guide

## Release Notes

- Remove dependency on RSolr::Ext. In this first stage, some RSolr::Ext code is now maintained in Blacklight, e.g.:
     - RSolr::Ext::Response::Facets => Blacklight::SolrResponse::Facets
     - RSolr::Ext::Doc => Blacklight::Solr::Document
     - etc

- Bootstrap-based view templates and default stylesheet; removed compass/susy 
- Drop support for Ruby 1.8; add support for Ruby 2.0 

And the usual bug-fixes (some of which are backported into 3.8.x):

- fix #64, show MoreLikeThis titles on record show page if available
- fix #422; show prev/next options even when not linked
- fix #450; support Solr 4.x and use it by default.
- fix #484, use top-level constant BLACKLIGHT_VERBOSE_LOGGING (uninitialized by default) to log the full solr response with each solr query
- fix #495 Remove blacklight_config.rb template
- fix #496, removing hard-coded 'id' field reference in BookmarksController
- remove unicode as an explicit Blacklight dependency, but use it if it is available
- fix #499 When document_heading is an array, don't draw the array bracket…
- fix #502, Endnote action tries to render partials and gives error
- update per_page widget to use i18n strings; don't require echoParams
- use 1.9-style string interpolation for template path lookups
- consolidate solr pagination information lookup.

## Plugins Compatibility

As of 11/26:

### Tested/Compatible

* blacklight_advanced_search
* blacklight_cql
* blacklight_range_limit
* blacklight_browse_nearby




## Upgrade Guide

When approaching the Blacklight 3.x => 4.0 upgrade, we'd strongly recommend adopting the bootstrap templates, update local overrides to use bootstrap, and do your own bootstrap stylesheet customization. 

That said, it should be possible to do a fairly straightforward in-place upgrade if you so choose. Most of the Blacklight 4.x work was limited to views, javascript and stylesheets. If you want to keep the old Blacklight theme, you should be able to grab them from Blacklight and drop them into your application directly. We wouldn't recommend it though.

To upgrade your application to Blacklight 4.x:

- Update your application's gem dependency to use Blacklight 4.0:

```ruby
gem 'blacklight', "~>4.0"
```

- Add the unicode gem to your application's Gemfile (if you want to use it to normalize character encoding for refworks integration):

```ruby
gem 'unicode'
```

- Remove compass/susy references; replace with bootstrap-sass:

```ruby
# REMOVE:
gem 'compass-rails', '~> 1.0.0', :group => :assets
gem 'compass-susy-plugin', '~> 0.9.0', :group => :assets

# ADD:
gem 'bootstrap-sass'
```

- (Remember to ```bundle install```)

- Add the following into your stylesheets directory (possibly as ```app/assets/stylesheets/blacklight.css.scss```):

```scss
@import 'bootstrap';
@import 'bootstrap-responsive';

@import 'blacklight/blacklight';
```

You no longer need the ```blacklight_themes directory``` and can remove ```require 'blacklight_themes/standard'``` (and the jquery UI css) from your application.css

In ```app/assets/javascripts/application.js```, you can also remove

```javascript
//= require jquery-ui
```

- If you have local overrides of stylesheets, javascript or view templates, you should update them appropriately. Be warned that some of the bootstrapped Blacklight HTML element classes and IDs may have shifted slightly, and the previous susy-grid and YUI class names have been removed.

In your `ApplicationController`, you need to tell your application which layout to use:

```ruby
# completely Blacklight 3.x-backwards compatible
layout :choose_layout

# if you don't need dynamic layout switching, just do the Rails-standard:
layout 'blacklight'
```

- If you are using devise-guests, you probably want to update to devise-guests ~> 0.3. After doing so,

```bash
$ rails g devise_guests
$ rake db:migrate
```

If you've already chosen a different layout for your application, you don't need to do anything at all.

Here are some minor differences elsewhere:

 - Some i18n strings have been updated to read better in the new UI
 - the helper `#render_document_heading` returns an h4 instead of an h1.
 - the helper `#document_show_fields` returns a hash instead of a list of keys

## Document partial paths

The default naming convention for format-specific partials was changed. In Blacklight 3.1, the default format-specific path was changed to `catalog/_index_[format_name].html.erb`, but support for the Blacklight 2.x style was left in place. In Blacklight 4, the Blacklight 2.x style was removed from the list of defaults.

So, if you have partials in a directory like:

```ruby
catalog/_index_partials/[format_name].html.erb
```

they should be moved to

```ruby
catalog/_index_[format_name].html.erb
```

Or, alternatively, you may override the helpers [document_index_path_templates](https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight/blacklight_helper_behavior.rb#L382) and [document_partial_path_templates](https://github.com/projectblacklight/blacklight/blob/master/app/helpers/blacklight/blacklight_helper_behavior.rb#L423) with a custom naming convention.