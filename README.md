# Blacklight

![CI Workflow](https://github.com/projectblacklight/blacklight/actions/workflows/ruby.yml/badge.svg)

## Branches

* The `main` branch is currently where we do new development for the upcoming 9.0 release.
* The `8.x` series is on the [release-8.x](https://github.com/projectblacklight/blacklight/tree/release-8.x) branch
* The `7.x` series is on the [release-7.x](https://github.com/projectblacklight/blacklight/tree/release-7.x) branch
* The `6.x` series is on the [release-6.x](https://github.com/projectblacklight/blacklight/tree/release-6.x) branch

## Description

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
* [Testing and Developing Blacklight](https://github.com/projectblacklight/blacklight/wiki/Testing-and-Developing-Blacklight)
* [Issue Tracker](https://github.com/projectblacklight/blacklight/issues)
* [Support](https://github.com/projectblacklight/blacklight/wiki/Support)

## Browser Compatibility

Blacklight assumes a modern browser with support for [Baseline 2023](https://web.dev/baseline/2023). This means we explicitly do not support Internet Explorer.

## Dependencies

* [Ruby](https://www.ruby-lang.org/) 3.1+
* [Ruby on Rails](https://rubyonrails.org/) 6.1+

Blacklight aims to support the currently [supported versions of Ruby](https://www.ruby-lang.org/en/downloads/branches/) and the [supported versions of Ruby on Rails](https://guides.rubyonrails.org/maintenance_policy.html).  We aim to keep our [test configuration](blob/main/.github/workflows/ruby.yml) up to date with these supported versions.

## Contributing Code

Code contributions are always welcome, instructions for contributing can be found at [CONTRIBUTING.md](https://github.com/projectblacklight/blacklight/blob/main/CONTRIBUTING.md).

## Configuring Apache Solr
You'll also want some information about how Blacklight expects [Apache Solr](http://lucene.apache.org/solr ) to run, which you can find in [Solr Configuration](https://github.com/projectblacklight/blacklight/wiki/Solr-Configuration#solr-configuration)

## Building the javascript
The javascript is built by npm from sources in `app/javascript` into a bundle
in `app/assets/javascripts/blacklight/blacklight.js`. This file should not be edited
by hand as any changes would be overwritten.  When any of the javascript
components in the gem are changed, this bundle should be rebuild with the
following steps:
1. [Install npm](https://www.npmjs.com/get-npm)
1. run `npm install` to download dependencies
1. run `npm run prepare` to build the bundle
1. run `npm publish` to push the javascript package to https://npmjs.org/package/blacklight-frontend

## Using the javascript
Blacklight ships with Javascript that can be compiled either by Webpacker or by
Sprockets. To use Webpacker see the directions at https://github.com/projectblacklight/blacklight/wiki/Using-Webpacker-to-compile-javascript-assets

If you prefer to use Sprockets, simply run the install generator, which will run the assets generator. For details see https://github.com/projectblacklight/blacklight/wiki/Using-Sprockets-to-compile-javascript-assets
