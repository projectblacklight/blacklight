# -*- coding: utf-8 -*-
version = File.read(File.expand_path("../../BLACKLIGHT_VERSION",__FILE__)).strip

Gem::Specification.new do |s|
  s.name        = "blacklight-bootstrap3"
  s.version     = version
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonathan Rochkind", "Matt Mitchell", "Chris Beer", "Jessie Keck", "Jason Ronallo", "Vernon Chapman", "Mark A. Matienzo", "Dan Funk", "Naomi Dushay", "Justin Coyne"]
  s.email       = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary     = "Bootstrap 3 front-end for Blacklight"
  s.description = %q{Blacklight is an open source Solr user interface discovery platform. You can use Blacklight to enable searching and browsing of your collections. Blacklight uses the Apache Solr search engine to search full text and/or metadata.}
  s.license     = "Apache 2.0"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- spec`.split("\n")
  s.require_paths = ["lib"]

  s.add_dependency "sass-rails"
  s.add_dependency "bootstrap-sass", "~> 3.0.2.1"
  s.add_dependency "blacklight-core", version
end
