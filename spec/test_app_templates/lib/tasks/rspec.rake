require 'rspec/core/rake_task'
desc "run the blacklight gem spec"
gem_home = File.expand_path('../../../../..', __FILE__)
RSpec::Core::RakeTask.new(:myspec) do |t|
  t.pattern = gem_home + '/spec/**/*_spec.rb'
  t.rspec_opts = "--colour"
  t.ruby_opts = "-I#{gem_home}/spec"
end
