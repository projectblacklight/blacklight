require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'

namespace :rsolr do
  
  desc "Starts the HTTP server used for running HTTP connection tests"
  task :start_test_server do
    system "cd apache-solr/example; java -jar start.jar"
  end
  
end

task :default => [:test_units]

desc "Run basic tests"
Rake::TestTask.new("test_units") { |t|
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
  t.warning = true
  t.libs << "test"
}

require 'spec/rake/spectask'

desc "Run specs"
Spec::Rake::SpecTask.new('spec') do |t|
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.libs += ["lib", "spec"]
end

#desc 'Run specs' # this task runs each test in its own process
#task :specs do
#  require 'rubygems'
#  require 'facets/more/filelist' unless defined?(FileList)
#  files = FileList["**/*_spec.rb"]
#  p files.to_a
#  files.each do |filename|
#    system "cd #{File.dirname(filename)} && ruby #{File.basename(filename)}"
#  end
#end

#desc "Run specs"
#Rake::TestTask.new("specs") { |t|
#  t.pattern = 'spec/**/*_spec.rb'
#  t.verbose = true
#  t.warning = true
#  t.libs += ["lib", "spec"]
#}

# Clean house
desc 'Clean up tmp files.'
task :clean do |t|
  FileUtils.rm_rf "doc"
  FileUtils.rm_rf "pkg"
end

# Rdoc
desc 'Generate documentation for the rsolr gem.'
Rake::RDocTask.new(:doc) do |rdoc|
  rdoc.rdoc_dir = 'doc'
  rdoc.title = 'RSolr'
  rdoc.options << '--line-numbers' << '--inline-source'
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end