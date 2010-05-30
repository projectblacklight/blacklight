# use the colorize library...
# until the plugin has been installed/downloaded, mock String #colorize
String.class_eval do
  def colorize color; self end
end

# this gets mixed into the template installer scope...
module BlacklightInstaller
  
  # set a variable here for the directory that the plugin gets installed into.
  # We do this because the repo name is "blacklight-plugin", which we don't want as the directory name.
  attr_accessor :install_dir_name
  
  # needed for the git/template/non-gem install
  attr_accessor :tag, :branch
  
  def output msg, color = :green
    prefix = "*" * 2
    message = msg.to_s.colorize color
    puts "#{prefix} #{message}"
  end
  
  def error! msg
    output msg, :red
    exit 0
  end
  
  # the bin/blacklight executable defines #blacklight_root
  def gem_install?
    respond_to? :blacklight_root
  end
  
  # Rails comes with a helper to install plugins but it doesn't give the ability to 
  # install a plugin from a git branch. Rails also comes with a Git.clone -- but
  # the branch option is broken -- this is why the git_export helper was created.
  # git_export expects a full git repo url, and an optional branch name.
  # It will clone the repo, checkout the remote branch and then remote the .git file.
  #
  # Example: git_export 'git://github.com/projectblacklight/blacklight.git', 'release-2.4'
  #
  # if a block is given, yield is called before the .git dir is removed
  def git_export repo, new_dir_name=nil, opts={}, &block
    if File.exists? install_path and (new_dir_name == install_path)
      new_location = "vendor/#{Time.now.to_i}-previous-blacklight"
      output "Moving your current Blacklight installation to #{new_location}", :red
      FileUtils.mv install_path, new_location
    end
    dir_name = new_dir_name || File.basename(repo, '.git')
    run "git clone #{repo} #{new_dir_name}"
    if opts[:branch]
      run "cd #{dir_name} && git checkout --track -b #{opts[:branch]} origin/#{opts[:branch]}"
    elsif opts[:tag]
      run "cd #{dir_name} && git checkout #{opts[:tag]}"
    end
    yield if block_given?
    FileUtils.rm_r "#{dir_name}/**/.git*", :force=>true
  end

  # modify_env_for_engines_boot! helper method
  # adds a line to the environment.rb file for properly loading the Engines plugin
  def modify_env_for_engines_boot!
    output "Adding Engines boot loader to your config/environment.rb file"
    env_data_copy = env_data.dup
    # create the line we want to add
    engines_boot = "require File.join(File.dirname(__FILE__), '../#{install_path}/vendor/plugins/engines/boot')"
    # only add this if it doesn't already exist
    if env_data_copy.scan(engines_boot).empty?
      # find this line in the environment.rb file...
      rails_boot = "require File.join(File.dirname(__FILE__), 'boot')"
      # convert it into a Regexp
      rails_boot_regexp = /require File\.join\(File\.dirname\(__FILE__\), 'boot'\)/#Regexp.escape rails_boot
      # replace the "rails_boot" with itself, a new line and the "engines_boot"
      env_data_copy.sub! rails_boot_regexp, "#{rails_boot}\n#{engines_boot}"
      # write the change to the file...
      File.open('config/environment.rb', 'w') {|f| f.puts env_data_copy }
    end
  end
  
  def install_path
    "vendor/plugins/#{install_dir_name}"
  end
  
  def install_base_plugin
    output "Installing base plugin code..."
    if source_arg = ARGV.detect{|v| v =~ /^blacklight-source/}
      installing_from = File.expand_path source_arg.split('=').last.strip
      output "Installing from #{installing_from}"
      FileUtils.cp_r installing_from, install_path
      FileUtils.rm_rf Dir["#{install_path}/**/.git*", "#{install_path}/jetty/logs"]
    else
      git_export 'git://github.com/projectblacklight/blacklight.git', install_path, :tag=>tag do
        require "#{install_path}/lib/colorize.rb"
        output "Updating data and jetty directories/submodules"
        FileUtils.cd install_path do
          `git submodule init && git submodule update`
        end
      end
    end
  end
  
  # does the blacklight plugin exist already?
  def already_installed?
    File.exists? install_path
  end
  
  # load up the current environment file as a string
  def env_data
    @env_data ||= File.read 'config/environment.rb'
  end
  
  # This adds a require line to the application_controller
  def modify_application_controller
    output "Modifying your app/controllers/application_controller.rb file..."
    app_controller_hack = "require_dependency( '#{install_path}/app/controllers/application_controller.rb')"
    app_controller = File.read('app/controllers/application_controller.rb')
    if app_controller.scan(app_controller_hack).empty?
      app_controller = "#{app_controller_hack}\n#{app_controller}"
      File.open('app/controllers/application_controller.rb', 'w'){|f|f.puts app_controller}
    end
  end
  
  # This adds a require line to the application_helper
  def modify_application_helper
    output "Modifying your app/helpers/application_helper.rb file..."
    app_helper_dep = "require 'vendor/plugins/#{install_dir_name}/app/helpers/application_helper.rb'"
    app_helper = File.read('app/helpers/application_helper.rb')
    if app_helper.scan(app_helper_dep).empty?
      app_helper = "#{app_helper_dep}\n#{app_helper}"
      File.open('app/helpers/application_helper.rb', 'w'){|f| f.puts app_helper}
    end
  end
  
  # Add the BL routes to the app's config/routes.rb file:
  def modify_routes
    output "Adding Blacklight routes to your application..."
    if File.read('config/routes.rb').scan("Blacklight::Routes.build map").empty?
      route "Blacklight::Routes.build map"
    end
  end
  
  # ask about installing apache solr
  def install_solr?
    if yes? "Would you like to install and configure Apache Solr now?"
      
      FileUtils.cp_r "#{install_path}/jetty", 'jetty'
      FileUtils.mkdir "jetty/logs" rescue nil
      
      output "To start Solr:", :yellow
      
      output "cd jetty && java -jar start.jar".colorize(:mode => :swap)
            
      output "Copying SolrMarc configs to config/SolrMarc"
      FileUtils.cp_r "#{install_path}/config/SolrMarc", 'config/SolrMarc'
      
      output "To index the test data into the plugin level solr for testing purposes execute:", :yellow
      output "rake solr:marc:index_test_data RAILS_ENV=test".colorize(:mode => :swap)
      
      output "To index the data for you application level solr for development purposes execute:", :yellow
      output "rake solr:marc:index_test_data".colorize(:mode => :swap)
      
    else
      output "Skipping Solr installation..."
    end
  end
  
  # Copy the database migrations to db/migrate
  def run_migrations?
    migrations_dir = 'db/migrate'
    output "Copying database migration files to #{migrations_dir}"
    FileUtils.mkdir_p migrations_dir
    FileUtils.cp Dir.glob("#{install_path}/#{migrations_dir}/*.rb"), migrations_dir
    # ask about migrating...
    rake "db:migrate" if yes? "Would you like to run the initial database migrations now?"
  end
  
  def yes? text
    super text.colorize(:light_blue)
  end
  
  # install the gem dependencies...
  # this will install each gem specified by the plugins
  # PROBLEM HERE -- it seems that running this with sudo=>true
  # makes the files downloaded afterward this owned by root. Ugh.
  #
  # because gems:install will cause Engines to copy the assets directory up to the app level
  # the public/plugin_assets directory will be owned by root.
  # so we need to change the ownder of public/plugin_assets back to the original user.
  def install_gem_dependencies?
    if yes?("Would you like to install the gem dependecies now?")
      if yes? "Do you want to install gems using sudo?"
        user = run("whoami").chomp
        run "sudo rake gems:install && sudo chown -R #{user} public/plugin_assets"
      else
        rake "gems:install", :sudo => false
      end
    end
  end
  
  # make sure github and gemcutter are in the gem sources list
  # TODO: remove this, everything is at gemcutter now (rubyforge points to gemcutter)
  # -- rubyforge is default for all gem installs
  def add_gem_repo_sources
    # output "Adding source repositories to your RubyGems installation if needed"
    # gem_sources = run "gem sources"
    # run "gem sources -a http://gems.github.com" unless gem_sources =~ /github/
    # run "gem sources -a http://gemcutter.org" unless gem_sources =~ /gemcutter/
  end
  
  # The authlogic gem needs to be specified in the environment.rb file,
  # so specifying it here will do just that.
  # Having it in the blacklight init.rb doesn't cut it because
  # Authlogic needs to modify ActionController::Base at a particular point
  # within the boot process, and the init.rb file is loaded after that point.
  def add_gem_dependencies_to_environment
    output "Adding AuthLogic gem dependency to your config/environment.rb file"
    if env_data.scan("config.gem 'authlogic'").empty?
      gem 'authlogic', :version=>'2.1.2'
    end
  end
  
  # add BL's plugins directory to the applications config.plugin_paths
  # This makes it possible to not have to install the other plugins BL uses.
  def register_plugin_dependencies
    output "Registering Blacklight's plugins in your config/environment.rb file"
    blacklight_plugins_path = 'config.plugin_paths += ["#{RAILS_ROOT}/' + install_path + '/vendor/plugins"]'
    if env_data.scan(blacklight_plugins_path).empty?
     environment blacklight_plugins_path
    end
  end
  
  # does what it says
  def remove_index_html
	  if File.exists?('public/index.html')
      output "Removing the default public/index.html file"
      FileUtils.rm 'public/index.html'
	  end
  end
  
  # copy the solr.yml from the plugin to the new app
  # cp the blacklight initializer file from the plugin up to the new app
  def copy_configs
    output "Installing the config/solr.yml file"
    solr_config = "config/solr.yml"
    unless File.exists? solr_config
      FileUtils.cp "#{install_path}/install/solr.yml", solr_config
    end
    output "Installing the config/initializers/blacklight_config.rb file"
    blacklight_config = "config/initializers/blacklight_config.rb"
    unless File.exists? blacklight_config
      FileUtils.cp "#{install_path}/config/initializers/blacklight_config.rb", blacklight_config
    end
  end
  
end

##########################
# Fun starts here.........
##########################

extend BlacklightInstaller

@tag = nil
@branch = nil
@install_dir_name = 'blacklight'

error! "Halting... looks like Blacklight has been installed here..." if already_installed?

install_base_plugin

modify_env_for_engines_boot!
add_gem_dependencies_to_environment
register_plugin_dependencies
remove_index_html
copy_configs
add_gem_repo_sources
install_gem_dependencies?
run_migrations?
modify_application_controller
modify_application_helper
modify_routes
install_solr?

output "*********************************************************"
output "******* Blacklight installation complete, enjoy. ******** "
output "*********************************************************"
output "*** Visit the Blacklight Google Group for info and help:"
output "*** http://groups.google.com/group/blacklight-development".colorize(:yellow)
output "*********************************************************"
