puts "\n* Blacklight Rails Template \n\n"

# set a variable here for the directory that the plugin gets installed into.
# We do this because the repo name is "blacklight-plugin", which we don't want as the directory name.
bl_dirname = 'blacklight'

tag = nil

# install the blacklight plugin - remove this when the github move is complete!
#plugin :blacklight, :svn => 'http://blacklight.rubyforge.org/svn/trunk/rails/vendor/plugins/blacklight'

# uncomment next line when the github move is complete!
#plugin :blacklight, :git=>'git://github.com/projectblacklight/blacklight.git'

# Rails comes with a helper to install plugins but it doesn't give the ability to 
# install a plugin from a git branch. Rails also comes with a Git.clone -- but
# the branch option is broken -- this is why the git_export helper was created.
# git_export expects a full git repo url, and an optional branch name.
# It will clone the repo, checkout the remote branch and then remote the .git file.
#
# Example: git_export 'git://github.com/projectblacklight/blacklight.git', 'release-2.4'
#
def git_export repo, new_dir_name=nil, opts={}
  if File.exists? 'vendor/plugins/blacklight' and (new_dir_name == 'vendor/plugins/blacklight')
    new_location = "vendor/#{Time.now.to_i}-previous-blacklight"
    puts "\n* Moving your current Blacklight installation to #{new_location}\n\n"
    FileUtils.mv 'vendor/plugins/blacklight', new_location
  end
  dir_name = new_dir_name || File.basename(repo, '.git')
  run "git clone #{repo} #{new_dir_name}"
  if opts[:branch]
    run "cd #{dir_name} && git checkout --track -b #{opts[:branch]} origin/#{opts[:branch]}"
  elsif opts[:tag]
    run "cd #{dir_name} && git checkout #{opts[:tag]}"
  end
  FileUtils.rm_r "#{dir_name}/.git", :force=>true
end

git_export 'git://github.com/projectblacklight/blacklight.git', 'vendor/plugins/blacklight', :tag=>tag

# read the environment.rb file into a string...
# -- this allows the script to know if this is a fresh install or not
ENV_DATA = File.read 'config/environment.rb'

# mv the blacklight-plugin to #{bl_dirname}
# uncomment next line when github move is complete!
#FileUtils.mv("vendor/plugins/blacklight-plugin", "vendor/plugins/#{bl_dirname}")

# modify_env_for_engines_boot! helper method
# adds a line to the environment.rb file for properly loading the Engines plugin
def modify_env_for_engines_boot!
  env_data = ENV_DATA.dup
  # create the line we want to add
  engines_boot = "require File.join(File.dirname(__FILE__), '../vendor/plugins/blacklight/vendor/plugins/engines/boot')"
  # only add this if it doesn't already exist
  if env_data.scan(engines_boot).empty?
    # find this line in the environment.rb file...
    rails_boot = "require File.join(File.dirname(__FILE__), 'boot')"
    # convert it into a Regexp
    rails_boot_regexp = /require File\.join\(File\.dirname\(__FILE__\), 'boot'\)/#Regexp.escape rails_boot
    # replace the "rails_boot" with itself, a new line and the "engines_boot"
    env_data.sub! rails_boot_regexp, "#{rails_boot}\n#{engines_boot}"
    puts "\n* Adding engines bootline to config/environment.rb"
    # write the change to the file...
    File.open('config/environment.rb', 'w') {|f| f.puts env_data }
  end
end

modify_env_for_engines_boot!

# The authlogic gem needs to be specified in the environment.rb file,
# so specifying it here will do just that.
# Having it in the blacklight init.rb doesn't cut it because
# Authlogic needs to modify ActionController::Base at a particular point
# within the boot process, and the init.rb file is loaded after that point.
if ENV_DATA.scan("config.gem 'authlogic'").empty?
  gem 'authlogic', :version=>'2.1.2'
end

# add BL's plugins directory to the applications config.plugin_paths
# This makes it possible to not have to install the other plugins BL uses.
blacklight_plugins_path = 'config.plugin_paths += ["#{RAILS_ROOT}/vendor/plugins/blacklight/vendor/plugins"]'
if ENV_DATA.scan(blacklight_plugins_path).empty?
 environment blacklight_plugins_path
end

# don't need that irritating index page
FileUtils.rm 'public/index.html'

# copy the solr.yml from the plugin to the new app
solr_config = "config/solr.yml"
unless File.exists? solr_config
  FileUtils.cp "vendor/plugins/#{bl_dirname}/install/solr.yml", solr_config
end

# cp the blacklight initializer file from the plugin up to the new app
blacklight_config = "config/initializers/blacklight_config.rb"
unless File.exists? blacklight_config
  FileUtils.cp "vendor/plugins/#{bl_dirname}/config/initializers/blacklight_config.rb", blacklight_config
end

# make sure github and gemcutter are in the gem sources list
gem_sources = run "gem sources"
run "gem sources -a http://gems.github.com" unless gem_sources =~ /github/
run "gem sources -a http://gemcutter.org" unless gem_sources =~ /gemcutter/

# install the gem dependencies...
# this will install each gem specified by the plugins
# PROBLEM HERE -- it seems that running this with sudo=>true
# makes the files downloaded afterward this owned by root. Ugh.
if yes?("Would you like to install the gem dependecies now?")
  if yes? "Do you want to install gems using sudo?"
    # because gems:install will cause Engines to copy the assets directory up to the app level
    # the public/plugin_assets directory will be owned by root.
    # so we need to change the ownder of public/plugin_assets back to the original user.
    user = run("whoami").chomp
    run "sudo rake gems:install && sudo chown -R #{user} public/plugin_assets"
  else
    rake "gems:install", :sudo => false
  end
end

# Copy the database migrations to db/migrate
migrations_dir = 'db/migrate'
puts "\n* Copying database migration files to #{migrations_dir}"
FileUtils.mkdir_p migrations_dir
FileUtils.cp Dir.glob("vendor/plugins/#{bl_dirname}/#{migrations_dir}/*.rb"), migrations_dir

# ask about migrating...
rake "db:migrate" if yes? "\n* Would you like to run the initial database migrations now?"

# terribly ugly hack for application_controller to work with resource_controller
# "require" and "require_dependency" DO NOT WORK
puts "\n* Modifying your app/controllers/application_controller.rb file..."
app_controller_hack = "require 'vendor/plugins/blacklight/app/controllers/application_controller.rb'"
app_controller = File.read('app/controllers/application_controller.rb')
if app_controller.scan(app_controller_hack).empty?
  app_controller = "#{app_controller_hack}\n#{app_controller}"
  File.open('app/controllers/application_controller.rb', 'w'){|f|f.puts app_controller}
end

# require_dependency for application_helper
puts "\n* Modifying your app/helpers/application_helper.rb file..."
app_helper_dep = "require 'vendor/plugins/blacklight/app/helpers/application_helper.rb'"
app_helper = File.read('app/helpers/application_helper.rb')
if app_helper.scan(app_helper_dep).empty?
  app_helper = "#{app_helper_dep}\n#{app_helper}"
  File.open('app/helpers/application_helper.rb', 'w'){|f| f.puts app_helper}
end

puts "\n* Adding Blacklight routes to your application..."
# Add the BL routes to the app's config/routes.rb file:
if File.read('config/routes.rb').scan("Blacklight::Routes.build map").empty?
  route "Blacklight::Routes.build map"
end

# ask about installing apache solr
begin
  if yes? "\n* Would you like to download and configure Apache Solr now?"
    
    git_export 'git://github.com/projectblacklight/blacklight-jetty.git', 'jetty', :tag=>tag
    
    puts "\n* To start solr:
    cd jetty
    java -jar start.jar
    "
    
    if yes? "\n* Would you like to download a sample dataset to load into your Blacklight installation?"
      git_export "git://github.com/projectblacklight/blacklight-data.git", 'data', :tag=>tag
      puts "\n* Copying SolrMarc configs to config/SolrMarc"
      FileUtils.cp_r 'vendor/plugins/blacklight/config/SolrMarc', 'config/SolrMarc'
      properties_file = File.read 'config/SolrMarc/config.properties'
      properties_file.gsub! /^solr\.path.*/, 'solr.path = ../../jetty/solr'
      File.open('config/SolrMarc/config.properties', 'w'){|f|f.puts properties_file}
      puts "\n* To index the test data, make sure solr is running, then execute:
    rake solr:marc:index MARC_FILE=data/test_data.utf8.mrc SOLR_WAR_PATH=jetty/webapps/solr.war
    "
    end
    
  else
    puts "\n* Skipping Solr installation..."
  end
rescue
  puts "\n* Solr download failed: #{$!}"
  puts "\n* You'll need to download a copy of solr."
end

puts "\n* Blacklight installation complete!"
