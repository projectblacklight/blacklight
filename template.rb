puts "\n* Blacklight Rails Template \n\n"

# set a variable here for the directory that the plugin gets installed into.
# We do this because the repo name is "blacklight-plugin", which we don't want as the directory name.
bl_dirname = 'blacklight'

# install the blacklight plugin - remove this when the github move is complete!
#plugin :blacklight, :svn => 'http://blacklight.rubyforge.org/svn/trunk/rails/vendor/plugins/blacklight'

# uncomment next line when the github move is complete!
plugin :blacklight, :git=>'git://github.com/projectblacklight/blacklight-plugin.git'

# mv the blacklight-plugin to #{bl_dirname}
# uncomment next line when github move is complete!
#FileUtils.mv("vendor/plugins/blacklight-plugin", "vendor/plugins/#{bl_dirname}")

# modify_env_for_engines_boot! helper method
# adds a line to the environment.rb file for properly loading the Engines plugin
def modify_env_for_engines_boot!
  # find this line in the environment.rb file...
  rails_boot = "require File.join(File.dirname(__FILE__), 'boot')"
  # convert it into a Regexp
  rails_boot_regexp = /require File\.join\(File\.dirname\(__FILE__\), 'boot'\)/#Regexp.escape rails_boot
  # create the line we want to add
  engines_boot = "require File.join(File.dirname(__FILE__), '../vendor/plugins/blacklight/vendor/plugins/engines/boot')"
  # read the environment.rb file into a string...
  env_data = File.read 'config/environment.rb'
  # replace the "rails_boot" with itself, a new line and the "engines_boot"
  env_data.sub! rails_boot_regexp, "#{rails_boot}\n#{engines_boot}"
  puts "\n* Adding engines bootline to config/environment.rb"
  # write the change to the file...
  File.open('config/environment.rb', 'w') {|f| f.puts env_data }
end

modify_env_for_engines_boot!

# The authlogic gem needs to be specified in the environment.rb file,
# so specifying it here will do just that.
# Having it in the blacklight init.rb doesn't cut it because
# Authlogic needs to modify ActionController::Base at a particular point
# within the boot process, and the init.rb file is loaded after that point.
gem 'authlogic', :version=>'2.1.2'

# add BL's plugins directory to the applications config.plugin_paths
# This makes it possible to not have to install the other plugins BL uses.
environment 'config.plugin_paths += ["#{RAILS_ROOT}/vendor/plugins/blacklight/vendor/plugins"]'

# don't need that irritating index page
FileUtils.rm 'public/index.html'

# copy the solr.yml from the plugin to the new app
FileUtils.cp "vendor/plugins/#{bl_dirname}/install/solr.yml", "config/solr.yml"
# cp the blacklight initializer file from the plugin up to the new app
FileUtils.cp "vendor/plugins/#{bl_dirname}/config/initializers/blacklight_config.rb", "config/initializers/blacklight_config.rb"

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
app_controller_hack = "eval File.read('vendor/plugins/blacklight/app/controllers/application_controller.rb')"
app_controller = File.read('app/controllers/application_controller.rb')
app_controller = "#{app_controller_hack}\n#{app_controller}"
File.open('app/controllers/application_controller.rb', 'w'){|f|f.puts app_controller}

# require_dependency for application_helper
puts "\n* Modifying your app/helpers/application_helper.rb file..."
app_helper_dep = "require_dependency 'vendor/plugins/blacklight/app/helpers/application_helper.rb'"
app_helper = File.read('app/helpers/application_helper.rb')
app_helper = "#{app_helper_dep}\n#{app_helper}"
File.open('app/helpers/application_helper.rb', 'w'){|f| f.puts app_helper}

puts "\n* Adding Blacklight routes to your application..."
# Add the BL routes to the app's config/routes.rb file:
unless File.read('config/routes.rb') =~ /Blacklight::Routes\.build map/
  route "Blacklight::Routes.build map"
end

# ask about installing apache solr
begin
  if yes? "\n* Would you like to download and configure Apache Solr now?"
    
    run "git clone git://github.com/projectblacklight/blacklight-jetty.git jetty && rm -Rf jetty/.git"
    
    puts "\n* To start solr:
    cd jetty
    java -jar start.jar
    "
    
    if yes? "\n* Would you like to download a sample dataset to load into your Blacklight installation?"
      run "git clone git://github.com/projectblacklight/blacklight-data.git data && rm -Rf data/.git"
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