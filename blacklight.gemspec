# -*- coding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'blacklight/version'

Gem::Specification.new do |s|
  s.name        = "blacklight"
  s.version     = Blacklight::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonathan Rochkind", "Matt Mitchell", "Chris Beer", "Jessie Keck", "Jason Ronallo", "Vernon Chapman", "Mark A. Matienzo", "Dan Funk", "Naomi Dushay", "Justin Coyne"]
  s.email       = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary     = "Blacklight provides a discovery interface for any Solr (http://lucene.apache.org/solr) index."
  s.description = %(Blacklight is an open source Solr user interface discovery platform.
    You can use Blacklight to enable searching and browsing of your
    collections. Blacklight uses the Apache Solr search engine to search
    full text and/or metadata.)
  s.license     = "Apache 2.0"

  s.files         = `git ls-files -z`.split("\x0")
  s.test_files    = s.files.grep(%r{^(test|spec|features)/})
  s.bindir        = 'exe'
  s.executables   = s.files.grep(%r{^exe/}) { |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.required_ruby_version = '>= 2.5'

  s.add_dependency "rails", '>= 5.1', '< 7'
  s.add_dependency "globalid"
  s.add_dependency "jbuilder", '~> 2.7'
  s.add_dependency "kaminari", ">= 0.15" # the pagination (page 1,2,3, etc..) of our search results
  s.add_dependency "deprecation"
  s.add_dependency "i18n", '>= 1.7.0' # added named parameters
  s.add_dependency "ostruct", '>= 0.3.2'
  s.add_dependency "view_component", '>= 2.28.0'

  s.add_development_dependency "rsolr", ">= 1.0.6", "< 3"  # Library for interacting with rSolr.
  s.add_development_dependency "rspec-rails", "~> 4.0.0.beta2"
  s.add_development_dependency "rspec-its"
  s.add_development_dependency "rspec-collection_matchers", ">= 1.0"
  s.add_development_dependency "capybara", '~> 3'
  s.add_development_dependency 'webdrivers'
  s.add_development_dependency 'selenium-webdriver'
  s.add_development_dependency 'engine_cart', '~> 2.1'
  s.add_development_dependency "equivalent-xml"
  s.add_development_dependency "simplecov"
  s.add_development_dependency "rubocop", '~> 0.85'
  s.add_development_dependency "rubocop-rails", '~> 2.6'
  s.add_development_dependency "rubocop-rspec", '~> 1.43'
  s.add_development_dependency "i18n-tasks"
  s.add_development_dependency "solr_wrapper"
end
