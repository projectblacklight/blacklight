blacklight_plugin_dir = "#{File.dirname(__FILE__)}/../.."

$LOAD_PATH.unshift(RAILS_ROOT + '/vendor/plugins/cucumber/lib') if File.directory?(RAILS_ROOT + '/vendor/plugins/cucumber/lib')

begin
  require 'cucumber/rake/task'

  Cucumber::Rake::Task.new(:features) do |t|
    t.fork = true
    t.rcov = true
    t.rcov_opts =   IO.readlines("#{blacklight_plugin_dir}/spec/rcov.opts").map {|l| l.chomp.split " "}.flatten
    t.cucumber_opts = %w{--format pretty}
  end
  task :features => 'db:test:prepare'
rescue LoadError
  desc 'Cucumber rake task not available'
  task :features do
    abort 'Cucumber rake task is not available. Be sure to install cucumber as a gem or plugin'
  end
end
