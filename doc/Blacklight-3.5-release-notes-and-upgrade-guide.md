# Blacklight 3.5 Release Notes And Upgrade Guide

## Release Notes
# Blacklight 3.5 Release notes
Blacklight 3.5.0 is now available. It introduces i18n support for Blacklight, allowing applications to change and modify Blacklight-provided text strings without the need to override partials (in addition to providing multi-lingual support).

- Fix #395, removing hard-coded no-reply@ email addresses from the ```RecordMailer``` (see below for upgrade notes)
- Consistent use of polymorphic routing to the show views for documents. ```solr_document_url``` and ```solr_document_path``` are now part of the engine-provided routes, rather than helper-provided.
- Refactor `blacklight.js` to take advantage of the Rails asset pipeline by moving separate blocks of code into individual files.
- Fix problem with mounting Blacklight applications at a suburi rather than a document.

The full list of Github issues are at:
https://github.com/projectblacklight/blacklight/issues?milestone=7&state=closed

Also, the GitHub compare view of this release vs. our last release is
located at:
https://github.com/projectblacklight/blacklight/compare/v3.4.2...release-3.5


## Upgrade Guide

No known issues updating from 3.4 to 3.5.

## i18n

Blacklight 3.5 introduces i18n (internationalization framework) support. See the Ruby on Rails [[i18n Rails guide|http://guides.rubyonrails.org/i18n.html]] for information on how to use i18n within your application. The list of blacklight-provided (English) translations are available in the engine's [[```config/locales/blacklight.en.yml```|https://github.com/projectblacklight/blacklight/blob/master/config/locales/blacklight.en.yml]]

## RecordMailer default email

In config/environments/development.rb:
```ruby
ActionMailer::Base.default :from => 'default@development-server.com'
```

In config/environments/production.rb:
```ruby
ActionMailer::Base.default :from => 'default@production-server.com'
```

You can also target the RecordMailer directly:

```ruby
RecordMailer.default :from => 'no-reply@projectblacklight.org'
```