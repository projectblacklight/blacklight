# Blacklight

[![Build Status](https://travis-ci.org/projectblacklight/blacklight.png?branch=master)](https://travis-ci.org/projectblacklight/blacklight) [![Gem Version](https://badge.fury.io/rb/blacklight.png)](http://badge.fury.io/rb/blacklight) [![Coverage Status](https://coveralls.io/repos/github/projectblacklight/blacklight/badge.svg?branch=master)](https://coveralls.io/github/projectblacklight/blacklight?branch=master)

Blacklight is an open source Solr user interface discovery platform.
You can use Blacklight to enable searching and browsing of your collections.
Blacklight uses the [Apache Solr](http://lucene.apache.org/solr) search engine
to search full text and/or metadata.  Blacklight has a highly
configurable Ruby on Rails front-end. Blacklight was originally developed at
the University of Virginia Library and is made public under an Apache 2.0 license.

## Installation

Add Blacklight to your `Gemfile`:

```ruby
gem "blacklight"
```

Run the install generator which will copy over some initial templates, migrations, routes, and configuration:

```bash
rails generate blacklight:install
```


## Documentation, Information and Support

* [Project Homepage](http://projectblacklight.org)
* [Developer Documentation](https://github.com/projectblacklight/blacklight/wiki)
* [Quickstart Guide](https://github.com/projectblacklight/blacklight/wiki/Quickstart)
* [Issue Tracker](https://github.com/projectblacklight/blacklight/issues)
* [Support](https://github.com/projectblacklight/blacklight/wiki/Support)

## Dependencies

* Ruby 2.1+
* Bundler
* Rails 5.0+

## Configuring Apache Solr
You'll also want some information about how Blacklight expects [Apache Solr](http://lucene.apache.org/solr ) to run, which you can find in [README_SOLR](https://github.com/projectblacklight/blacklight/wiki/README_SOLR)

## Building the javascript
The javascript is built by npm from sources in `app/javascript` into a bundle
in `app/assets/javascripts/blacklight/blacklight.js`. This file should not be edited
by hand as any changes would be overwritten.  When any of the javascript
components in the gem are changed, this bundle should be rebuild with the
following steps:
1. [Install npm](https://www.npmjs.com/get-npm)
1. run `npm install` to download dependencies
1. run `npm run js-compile-bundle` to build the bundle
1. run `npm publish` to push the javascript package to https://npmjs.org/package/blacklight-frontend

## Using the javascript
Blacklight ships with Javascript that can be compiled either by Webpacker or by
Sprockets. To use Webpacker see the directions at https://github.com/projectblacklight/blacklight/wiki/Using-Webpacker-to-compile-javascript-assets

If you prefer to use Sprockets, simply run the install generator, which will run the assets generator. For details see https://github.com/projectblacklight/blacklight/wiki/Using-Sprockets-to-compile-javascript-assets
