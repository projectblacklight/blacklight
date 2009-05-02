$LOAD_PATH.unshift(RAILS_ROOT + '/vendor/plugins/cucumber/lib') if File.directory?(RAILS_ROOT + '/vendor/plugins/cucumber/lib')

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new("blacklight:plugin:features") do |t|
    t.cucumber_opts = "--format pretty"
    t.feature_pattern = "vendor/plugins/blacklight/features/**/*.feature"
    t.step_pattern    = "vendor/plugins/blacklight/features/**/*.rb"
  end
  task :features => 'db:test:prepare'
rescue LoadError
  desc 'Cucumber rake task not available'
  task "blacklight:plugin:features" do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end