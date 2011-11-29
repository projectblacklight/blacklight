# -*- coding: utf-8 -*-
require File.join(File.dirname(__FILE__), "lib/blacklight/version")

Gem::Specification.new do |s|
  s.name        = "blacklight"
  s.version     = Blacklight::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Jonathan Rochkind", "Matt Mitchell", "Chris Beer", "Jessie Keck", "Jason Ronallo", "Vernon Chapman", "Mark A. Matienzo", "Dan Funk"]
  s.email       = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary     = "A next-generation Library Catalag for Universities"
  s.description = %q{Blacklight is a free and open source ruby-on-rails based discovery interface (a.k.a. “next-generation catalog”) especially optimized for heterogeneous collections. You can use it as a library catalog, as a front end for a digital repository, or as a single-search interface to aggregate digital content that would otherwise be siloed.}
  
  s.rubyforge_project = "blacklight"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # PRODUCTION GEM REQUIREMENTS
  # ---------------------------------------   
  s.add_dependency "rails", "~> 3.1.1"
  s.add_dependency "nokogiri", "~>1.5"   # XML Parser
  s.add_dependency "unicode" # provides C-form normalization of unicode characters, as required by refworks.
  s.add_dependency "marc", "~> 0.4.3"  # Marc record parser
  s.add_dependency "rsolr",  '1.0.2' # Library for interacting with rSolr.
  s.add_dependency "rsolr-ext", '1.0.3' # extension to the above for some rails-ish behaviors - currently embedded in our solr document ojbect.
  s.add_dependency "kaminari" # the pagination (page 1,2,3, etc..) of our search results
  s.add_dependency "sass-rails", "~> 3.1.1"
  s.add_dependency "compass", ">= 0.12.alpha.a"
  s.add_development_dependency "jettywrapper", ">= 1.2.0"
end
