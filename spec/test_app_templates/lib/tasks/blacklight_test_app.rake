require 'rspec/core/rake_task'

desc "run the blacklight gem spec"
gem_home = File.expand_path('../../../../..', __FILE__)

namespace :blacklight_test_app do

  RSpec::Core::RakeTask.new(:spec) do |t|
    t.pattern = gem_home + '/spec/**/*_spec.rb'
    t.rspec_opts = "--colour"
    t.ruby_opts = "-I#{gem_home}/spec"
  end

end
