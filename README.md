# Blacklight

Blacklight is open source discovery software. Libraries (or anyone else) can use Blacklight to enable searching and browsing of their collections online. Blacklight uses the [Apache SOLR](http://lucene.apache.org/solr) search engine to index and search full text and/or metadata, and Blacklight has a highly configurable Ruby on Rails front-end. Blacklight was originally developed at the University of Virginia Library and is made public under an Apache 2.0 license. 


## Documentation, Information and Support

* [Project Homepage](http://projectblacklight.org)
* [Developer Documentation](https://github.com/projectblacklight/blacklight/wiki)
* [Quickstart Guide](https://github.com/projectblacklight/blacklight/wiki/Quickstart)
* [JIRA Issue Tracker](http://jira.projectblacklight.org/jira/secure/Dashboard.jspa)
* [Support](http://projectblacklight.org/support.html)

## Dependencies

* ruby v1.8.7 or higher 
* git
* java 1.5 or higher
* access to a command prompt on the machine to install

In addition, you must have the Bundler and Rails 3.0 gems installed. Other gem dependencies are defined in the blacklight.gemspec file and will be automatically loaded by Bundler.

## Configuring Apache Solr 
You'll also want some information about how Blacklight expects [Apache SOLR](http://lucene.apache.org/solr ) to run, which you can find in [README_SOLR](https://github.com/projectblacklight/blacklight/wiki/README_SOLR)
