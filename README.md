# Blacklight

[![Build Status](https://travis-ci.org/projectblacklight/blacklight.png?branch=master)](https://travis-ci.org/projectblacklight/blacklight) [![Gem Version](https://badge.fury.io/rb/blacklight.png)](http://badge.fury.io/rb/blacklight)

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

```
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
* Rails 4.2+

## Configuring Apache Solr 
You'll also want some information about how Blacklight expects [Apache Solr](http://lucene.apache.org/solr ) to run, which you can find in [README_SOLR](https://github.com/projectblacklight/blacklight/wiki/README_SOLR)
