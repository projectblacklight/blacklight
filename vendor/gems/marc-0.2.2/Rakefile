RUBY_MARC_VERSION = '0.2.2'

require 'rubygems'
require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'

task :default => [:test]

Rake::TestTask.new('test') do |t|
  t.libs << 'lib'
  t.pattern = 'test/tc_*.rb'
  t.verbose = true
  t.ruby_opts = ['-r marc', '-r test/unit']
end

spec = Gem::Specification.new do |s|
  s.name = 'marc'
  s.version = RUBY_MARC_VERSION
  s.author = 'Ed Summers'
  s.email = 'ehs@pobox.com'
  s.homepage = 'http://www.textualize.com/ruby_marc'
  s.platform = Gem::Platform::RUBY
  s.summary = 'A ruby library for working with Machine Readable Cataloging'
  s.files = Dir.glob("{lib,test}/**/*") + ["Rakefile", "README", "Changes",
    "LICENSE"]
  s.require_path = 'lib'
  s.autorequire = 'marc'
  s.has_rdoc = true
  s.required_ruby_version = '>= 1.8.6'
  
  s.test_file = 'test/ts_marc.rb'
  s.bindir = 'bin'
end

Rake::GemPackageTask.new(spec) do |pkg|
  pkg.need_zip = true
  pkg.need_tar = true
end

Rake::RDocTask.new('doc') do |rd|
  rd.rdoc_files.include("lib/**/*.rb")
  rd.main = 'MARC::Record'
  rd.rdoc_dir = 'doc'
end
