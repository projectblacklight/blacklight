> NOTE: This wiki provides developer documentation for the latest Blacklight release. For documentation of older releases, see the end of this page.

Blacklight is an open source, Ruby on Rails Engine that provides a basic discovery interface for searching an [Apache Solr](http://lucene.apache.org/solr) index, and provides search box, facet constraints, stable document urls, etc., all of which is customizable via Rails (templating) mechanisms. Blacklight accommodates heterogeneous data, allowing different information displays for different types of objects. 

Some other features include:

* Stable URLs for search and record pages allow users to bookmark, share, and save search queries for later access
* Every Blacklight search provides RSS and Atom Responses of search results
* For certain types of solr documents, an OpenURL/Z39.88 COinS object is embedded in each document, which allows plugins like Zotero to easily extract data from the page.
* Blacklight supports OpenSearch, a collection of simple formats for the sharing of search results.
* Faceted searching
* Search queries can be targeted at specific sets of fields
* Results sorting
* Tools for exporting records to Refworks or Endnote, sending records via Email or SMS, or as a formatted citation.

## About this guide

This wiki provides high-level documentation of Blacklight and supplements the low-level [RubyDocs](http://rubydoc.info/gems/blacklight). It is structured to address a broad spectrum of needs, ranging from new developers getting started to well-experienced developers extending their application or troubleshooting. It should be of use at any point in the application life cycle.

This wiki assumes you have prior experience with Ruby and Ruby on Rails. If you have no prior experience with either, you will find a very steep learning curve diving straight into Blacklight. There are some good free resources on the internet for learning Ruby, including:

- [Mr. Neighborly's Humble Little Ruby Book](http://www.humblelittlerubybook.com/)
- [Programming Ruby](http://ruby-doc.com/docs/ProgrammingRuby/)
- [Why's (Poignant) Guide to Ruby](http://mislav.uniqpath.com/poignant-guide/)

And resources for learning Rails, including:

- [Rails tutorial](http://ruby.railstutorial.org/)
- [Learn Rails](https://learn.thoughtbot.com/rails)
- [Railsbridge](http://docs.railsbridge.org/docs/)

In order to fully understand this guide, you should also familiarize yourself with Apache Solr, ways to index data into Solr, how to configure request handlers, and the Solr schema format. Those topics are covered in the official [Apache Solr Tutorial](http://lucene.apache.org/solr/tutorial.html).

## Blacklight features
* [[Basic features|Blacklight out-of-the-box]]
* [[Internationalization]]: Translating (or simply customizing) the Blacklight copy
* APIs: [[Atom Responses]], [[JSON API]]
* [[Directory of Blacklight Plugins/Addons|Blacklight-Add-ons]]

## Blacklight Configuration

Blacklight tries to address the "80% use case" out of the box and through some simple configuration can be adapted to work with your data. The available Blacklight configuration, and their default values, is shown in
[`blacklight/configuration.rb`](https://github.com/projectblacklight/blacklight/tree/master/lib/blacklight/configuration.rb).

The Blacklight configuration is an `OpenStruct`; in addition to the Blacklight-defined configuration discussed in the sections below, you may also add application-specific configuration (e.g. for controlling behavior in overridden partials) or plugin-specific configuration.

* [[Solr Configuration]]
* [[Discovery|Configuration - Solr fields]]
* [[Results view|Configuration - Results View]]
* [[Facets|Configuration - Facet Fields]]

## Blacklight Customization

There are many ways to override specific behaviors and views in Blacklight. Because Blacklight is distributed as a Rails engine-based gem, all customization of Blacklight behavior should be done within your application by overriding Blacklight-provided behaviors with your own.

* [[Understanding Rails and Blacklight]] How the Blacklight engine integrates with your application
* [[Extending or Modifying Blacklight Search Behavior]] How to change the way the Blacklight discovery feature works.
* [[Adding new document actions]] How to extend the document actions with application-specific behavior

### Customizing the UI

* [[Theming]]: Overriding the Blacklight CSS
* [[Providing your own view templates]]: Overriding the out-of-the-box Blacklight templates the Rails way.
* [[Pagination]]: Advice on how to customize pagination with Kaminari

### Other Customizations
* [[User Authentication]]: Connecting Blacklight with an existing Authentication system
* [[Configuring Rails Routes]]
* [[Indexing your data into Solr]]
* [[Additional Blacklight-specific Solr documentation|README_SOLR]]

## Support
Don't be scared to ask a question on the [[Blacklight mailing list|http://groups.google.com/group/blacklight-development]]. We appreciate you checking the documentation first and asking an educated question, but don't beat your head against the wall -- sometimes the existing documentation may be out of date and inaccurate.

In order to reduce spam, the first time you post your email will be held in a moderation queue, but as soon as your first message is approved your posts won’t be held for moderation any longer. 

Some Blacklight developers aso hang out on our IRC channel, usually during North American office hours. On `chat.freenode.net`, channel `#blacklight`. Stop in and say hi, we're happy to help with questions when we have time. [[http://freenode.net/faq.shtml]].

* [[Bug Tracker|https://github.com/projectblacklight/blacklight/issues/]]
* [[Mailing List|http://groups.google.com/group/blacklight-development]]
* [![Build Status](https://travis-ci.org/projectblacklight/blacklight.png?branch=master)](https://travis-ci.org/projectblacklight/blacklight)

## Contributing to Blacklight

* [[Contributing to Blacklight]]
* [[How to release a version]]
* [[Testing]]

### Older Documentation
This wiki provides developer documentation for the ```master``` branch of Blacklight, which may include documentation of features not present in every Blacklight version. For documentation of specific Blacklight releases, see also:

* [[Home]]
* [[Blacklight 4.7|https://github.com/projectblacklight/blacklight/tree/release-4.7/doc]]
* [[Blacklight 3.x|https://github.com/projectblacklight/blacklight/tree/release-3.8/doc]]
* [[Blacklight 3.0 or 3.1|https://github.com/projectblacklight/blacklight/tree/release-3.1/doc]]
* [[Blacklight 2.x|https://github.com/projectblacklight/blacklight/tree/v2.9-frozen/doc]] for all Blacklight 2.x releases; version-specific documentation is also available:
    * [[Blacklight 2.7|https://github.com/projectblacklight/blacklight/tree/v2.7.0/doc]]
    * [[Blacklight 2.6|https://github.com/projectblacklight/blacklight/tree/v2.6.0/doc]]
    * [[Blacklight 2.5|https://github.com/projectblacklight/blacklight/tree/v2.5.0/doc]]
    * [[Blacklight 2.4|https://github.com/projectblacklight/blacklight/tree/v2.4.2/doc]]