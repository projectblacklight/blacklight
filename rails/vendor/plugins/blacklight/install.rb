require 'fileutils'

blacklight_dir = File.join(RAILS_ROOT, 'vendor', 'plugins', 'blacklight')
gems_dir = File.join(RAILS_ROOT, 'vendor', 'gems')
bl_gems_dir = File.join(blacklight_dir, 'vendor', 'gems')
config_dir = File.join(RAILS_ROOT, 'config')
migrate_dir = File.join(RAILS_ROOT, 'db', 'migrate')
bl_migrate_dir = File.join(blacklight_dir, 'db', 'migrate')
plugin_script =  File.join(RAILS_ROOT, 'script', 'plugin')
environment_file =  File.join(RAILS_ROOT, 'config', 'environment.rb')

# Abort with message if not on a supported verson of Rails
if defined? RAILS_GEM_VERSION
  abort("\n***** You need Rails Version >= 2.3.2. You have #{RAILS_GEM_VERSION}. Aborting. *****\n\n") unless RAILS_GEM_VERSION =~ /^[2-3]\.[3-9]\.[2-9]/
end

# Install the Engines plugin
puts "* installing Rails Engines plugin..."
result = Kernel.system("#{plugin_script} install git://github.com/lazyatom/engines.git")
puts "result: #{result}"


# This large section updates the config/environment.rb file
puts "\n\n* Adding needed configuration lines to environment.rb"

lines = File.readlines(environment_file)
lines.collect! {|line| line.rstrip}
joined_lines = lines.join("\n")
# puts joined_lines

new_line = "require File.join(File.dirname(__FILE__), '../vendor/plugins/engines/boot')"
unless joined_lines =~ /vendor\/plugins\/engines\/boot/
  index = lines.index("require File.join(File.dirname(__FILE__), 'boot')")
  lines.insert((index + 1), new_line)
  File.open(environment_file, "w+") do |file|
    lines.each { |line| file.puts line }
  end
end


# add the plugins, plugin paths and gems in the config block. 
[
  [/engines blacklight acts_as_taggable_on_steroids resource_controller/, %Q{  config.plugins = %W(engines blacklight acts_as_taggable_on_steroids resource_controller)}],
  [/vendor\/plugins\/blacklight\/vendor\/plugins/, %Q{  config.plugin_paths += ["\#{RAILS_ROOT}/vendor/plugins/blacklight/vendor/plugins"]}],
  [/config\.gem\s+['"]authlogic['"]/, %Q{  config.gem 'authlogic'}]
].each do |pair|
  new_line = pair.last
  unless joined_lines =~ pair.first
    index = lines.index("Rails::Initializer.run do |config|")
    lines.insert((index + 1), new_line)
    File.open(environment_file, "w+") do |file|
      lines.each { |line| file.puts line }
    end
  end
end #each pair

# Copy authlogic gem to vendor/gems
puts "* Copying the authlogic gem to your vendor/gems directory"
FileUtils.mkdir_p(gems_dir)
authlogic_dir = Dir.glob("#{bl_gems_dir}/authlogic*").first.split("/").last
FileUtils.cp_r(File.join(bl_gems_dir, authlogic_dir), File.join(gems_dir, authlogic_dir), :preserve => true)

# Copy install/solr.rb to config/
puts "* Copying solr.rb to config directory."
FileUtils.cp(File.join(blacklight_dir, 'install', 'solr.yml'), config_dir)

# Copy the database migrations to db/migrate
puts "* Copying database migration files to db/migrate"
FileUtils.mkdir_p(migrate_dir)
migration_files = Dir.glob("#{bl_migrate_dir}/*.rb")
FileUtils.cp(migration_files, "#{migrate_dir}/")

# Copy the Blacklight Config file to config/initializers
puts "* Copying the default blacklight_config.rb file to config/initializers. Update this for your own needs."
FileUtils.cp(File.join(blacklight_dir, 'config', 'initializers', 'blacklight_config.rb'), File.join(config_dir, 'initializers', 'blacklight_config.rb'))

puts "

* Blacklight was successfully installed!

"
