#
[[https://github.com/projectblacklight/projectblacklight.github.com/raw/master/images/logo.png]]

## Introduction

Blacklight is an open source, Ruby on Rails engine/gem that provides a discovery interface for  [Apache Solr](http://lucene.apache.org/solr). Blacklight provides a basic user interface for searching a Solr index, and provides search box, facet constraints, stable document urls, etc., all of which is customizable via Rails (templating) mechanisms.  Blacklight accommodates heterogeneous data, allowing different information displays for different types of objects. 

Some other features include:

* Stable URLs for search and record pages allow users to bookmark, share, and save search queries for later access
* Every Blacklight search provides RSS and Atom Responses of search results
* For certain types of solr documents, an OpenURL/Z39.88 COinS object is embedded in each document, which allows plugins like Zotero to easily extract data from the page.
* Blacklight supports OpenSearch, a collection of simple formats for the sharing of search results.
* Faceted searching
* Search queries can be targeted at specific sets of fields
* Results sorting
* Tools for exporting records to Refworks or Endnote, sending records via Email or SMS, or as a formatted citation.

A [demo application](http://demo.projectblacklight.org) uses the latest version of Blacklight to display a basic library catalog.

> NOTE: This wiki provides developer documentation for the latest Blacklight release. For documentation of older releases, see the end of this page.

## Getting Started
* [[Quickstart Guide|Quickstart]]
* [[Site Search|http://projectblacklight.org/search.html]]
* [[Demo|http://demo.projectblacklight.org]]
* [[Example installations|Examples]]
* [[Release Notes And Upgrade Guides]]

## Developing your application
* [[Blacklight Configuration]]: Search results, facets, query fields
* [[Providing your own view templates]]: Overriding the out-of-the-box Blacklight templates the Rails way.
* [[Theming]]: Overriding the Blacklight CSS
* [[User Authentication]]: Connecting Blacklight with an existing Authentication system
* [[Extending or Modifying Blacklight Search Behavior]] How to change the way the Blacklight discovery feature works.
* [[Internationalization]]: Translating (or simply customizing) the Blacklight copy
* [[Common Blacklight Patterns]]
* [[JSON API]]
* [[Configuring Rails Routes]]
* [[Indexing your data into Solr]]
* [[Additional Blacklight-specific Solr documentation|README_SOLR]]
* [[Blacklight on Heroku]]
* [[Pagination]]: Advice on how to customize pagination with Kaminari
* [[Blacklight Plugins/Addons|Blacklight-Add-ons]]


## Support
Don't be scared to ask a question on the [[Blacklight mailing list|http://groups.google.com/group/blacklight-development]]. We appreciate you checking the documentation first and asking an educated question, but don't beat your head against the wall -- sometimes the existing documentation may be out of date and inaccurate.

In order to reduce spam, the first time you post your email will be held in a moderation queue, but as soon as your first message is approved your posts won’t be held for moderation any longer. 

Some Blacklight developers aso hang out on our IRC channel, usually during North American office hours. On `chat.freenode.net`, channel `#blacklight`. Stop in and say hi, we're happy to help with questions when we have time. [[http://freenode.net/faq.shtml]].

* [[Bug Tracker|https://github.com/projectblacklight/blacklight/issues/]]
* [[Mailing List|http://groups.google.com/group/blacklight-development]]
* [![Build Status](https://travis-ci.org/projectblacklight/blacklight.png?branch=master)](https://travis-ci.org/projectblacklight/blacklight)

## Contributing to Blacklight

* [[Contributing to Blacklight]]
* [[Community Principles]]
* [[How to release a version]]
* [[Testing]]

## Releases
Blacklight releases are published on the [[Rubygems.org blacklight project|https://rubygems.org/gems/blacklight]].

For a list of features and bugfixes in Blacklight releases, see the [[Release announcements|Release Notes And Upgrade Guides]] on this wiki.

### Older Documentation
This wiki provides developer documentation for the ```master``` branch of Blacklight, which may include documentation of features not present in every Blacklight version. For documentation of specific Blacklight releases, see also:

* [[Home]]
* [[Blacklight 3.x|https://github.com/projectblacklight/blacklight/tree/release-3.8/doc]]
* [[Blacklight 3.0 or 3.1|https://github.com/projectblacklight/blacklight/tree/release-3.1/doc]]
* [[Blacklight 2.x|https://github.com/projectblacklight/blacklight/tree/v2.9-frozen/doc]] for all Blacklight 2.x releases; version-specific documentation is also available:
    * [[Blacklight 2.7|https://github.com/projectblacklight/blacklight/tree/v2.7.0/doc]]
    * [[Blacklight 2.6|https://github.com/projectblacklight/blacklight/tree/v2.6.0/doc]]
    * [[Blacklight 2.5|https://github.com/projectblacklight/blacklight/tree/v2.5.0/doc]]
    * [[Blacklight 2.4|https://github.com/projectblacklight/blacklight/tree/v2.4.2/doc]]