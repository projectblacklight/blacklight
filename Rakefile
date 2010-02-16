require(File.join(File.dirname(__FILE__), 'config', 'boot'))

require 'rake'
require 'rake/testtask'
require 'rake/rdoctask'
require 'tasks/rails'

# the default rake task
desc "run migrations and call solr:spec and solr:features"
task :default => "test"

# run migrations and call solr:spec and solr:features
desc 'run migrations and call solr:spec and solr:features'
task "test" => ["db:migrate", "solr:spec", "solr:features"] do
  # ...
end

desc 'Generate documentation for the blacklight plugin.'
Rake::RDocTask.new('rdoc') do |t| 
  t.rdoc_files.include('README.rdoc', 'lib/**/*.rb') 
  t.main = 'README.rdoc' 
  t.title = "Blacklight API documentation" 
  t.options << '--line-numbers' << '--inline-source'
end