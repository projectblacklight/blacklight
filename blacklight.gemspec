# -*- coding: utf-8 -*-
require "lib/blacklight/version"

Gem::Specification.new do |s|
  s.name        = "blacklight"
  s.version     = Blacklight::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["jrochkind", "Matt Mitchell", "Chris Beer", "Jessie Keck", "Jason Ronallo", "Vernon Chapman", "Marck A. Matienzo"]
  s.email       = ["blacklight-development@googlegroups.com"]
  s.homepage    = "http://projectblacklight.org/"
  s.summary     = "A next-geration Library Catalag for Universities"
  s.description = %q{Blacklight is a free and open source ruby-on-rails based discovery interface (a.k.a. “next-generation catalog”) especially optimized for heterogeneous collections. You can use it as a library catalog, as a front end for a digital repository, or as a single-search interface to aggregate digital content that would otherwise be siloed.}
  
  s.rubyforge_project = "blacklight"
  
  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_dependency "rails", ">= 3.0.3"
  
  # JRuby Specific Gems - and their counterparts
  if defined?(JRUBY_VERSION)
    s.add_dependency "jdbc-sqlite3"
    s.add_dependency "activerecord"
    s.add_dependency "activerecord-jdbc-adapter"
    s.add_dependency "jruby-openssl"
    s.add_dependency "jruby-rack"
    s.add_dependency "nokogiri", "~>1.5.0.beta.3" # NOTE: this pre-release is only required if you want PURE java, current nokogiri works fine if you have libxml2 binaries installed.  See https://github.com/tenderlove/nokogiri/wiki/pure-java-nokogiri-for-jruby
    s.add_dependency "warbler"    
  else
    s.add_dependency "sqlite3-ruby" #, :require => 'sqlite3'
    s.add_dependency "unicode"
  end  

  # Required Gems
  s.add_dependency "authlogic" #, :git => 'git://github.com/binarylogic/authlogic.git'
  s.add_dependency "marc"
  s.add_dependency "will_paginate", "3.0.pre2"
  s.add_dependency "acts-as-taggable-on"
  s.add_dependency "paperclip"
  s.add_dependency "capistrano"
  s.add_dependency "rsolr",  '1.0.0' # source :gemcutter
  s.add_dependency "rsolr-ext", '1.0.0' # source :gemcutter

  # For testing the generators
  s.add_dependency "rspec-rails", "~>2.3.0"
  s.add_dependency "cucumber-rails"
  s.add_dependency "database_cleaner"
  s.add_dependency "capybara"
  s.add_dependency "webrat"
  s.add_dependency "aruba"

end
