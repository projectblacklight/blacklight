# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "lib/blacklight/version")

Gem::Specification.new do |s|
  s.name        = "blacklight"
  s.version     = Blacklight::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonathan Rochkind", "Matt Mitchell", "Chris Beer", "Jessie Keck", "Jason Ronallo", "Vernon Chapman", "Mark A. Matienzo", "Dan Funk", "Naomi Dushay", "Justin Coyne"]
  s.email       = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary     = "Blacklight provides a discovery interface for any Solr (http://lucene.apache.org/solr) index."
  s.description = %q{Blacklight is an open source Solr user interface discovery platform. You can use Blacklight to enable searching and browsing of your collections. Blacklight uses the Apache Solr search engine to search full text and/or metadata.}
  s.license     = "Apache 2.0"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "rails",     ">= 3.2.6", "< 5"
  s.add_dependency "nokogiri",  "~>1.6"     # XML Parser
  s.add_dependency "kaminari", "~> 0.13"  # the pagination (page 1,2,3, etc..) of our search results
  s.add_dependency "rsolr",     "~> 1.0.6"  # Library for interacting with rSolr.
  s.add_dependency "bootstrap-sass", "~> 3.2"
  s.add_dependency "deprecation"

  s.add_development_dependency "jettywrapper", ">= 1.7.0"
  s.add_development_dependency "blacklight-marc", "~> 5.0"
  s.add_development_dependency "rspec-rails", "~> 3.0"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "rspec-collection_matchers", ">= 1.0"
  s.add_development_dependency "capybara"
  s.add_development_dependency "poltergeist"
  s.add_development_dependency 'engine_cart', ">= 0.6.0"
  s.add_development_dependency "equivalent-xml"
end
