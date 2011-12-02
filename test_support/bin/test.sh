#!/bin/bash
# test.sh
# Create a default rails appliaction, install blacklight, and run all the tests.

before="$(date +%s)"
benchmark() 
{
    after="$(date +%s)"
    elapsed_seconds="$(expr $after - $before)"
    echo "Total Time: ${elapsed_seconds} sec"
    # as a bonus, make our script exit with the right error code.
}

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR # ${1} : ${2}"
     benchmark
     exit 1
  fi
}

# Make sure we are in the blacklight directory
if [ ! -f "blacklight.gemspec" ]
then
  echo "You must execute test.sh from the root of your blacklight checkout."
  exit 1
fi

# Clear out the tmp/ directory.
rm -rf tmp/test_app
mkdir -p tmp/test_app
cd tmp

# Make certain rvn will work correctly.
# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
  exit 1
fi


rvm use "$@" --create
check_errs $? "rvm failed.  please run 'rvm install $@', and then re-run these tests." 

if ! gem query -n rails -v ">=3.1.1" --installed > /dev/null; then
  gem install --no-rdoc --no-ri 'rails'
fi

if ! gem query -n bundler -v ">=1.0" --installed > /dev/null; then
  gem install --no-rdoc --no-ri 'bundler'
fi

rails new test_app
cd test_app
echo "
source 'http://rubygems.org'
gem 'rack', '1.3.3'
gem 'rails', '~> 3.1.1'
platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3'
  gem 'mediashelf-loggable', '>= 0.4.8'
end
platforms :ruby do
 gem 'sqlite3-ruby', :require => 'sqlite3'
end
gem 'blacklight', :path => '../../'
gem 'jquery-rails'

group :assets do
  gem 'sass-rails', '~> 3.1.1'
  gem 'coffee-rails', '~> 3.1.1'
  gem 'uglifier'
  gem 'compass', '0.12.alpha.2'
   
  platforms :ruby do
    gem 'execjs'
    gem 'therubyracer'
  end

  platforms :jruby do
    gem 'therubyrhino'
  end
end


# For testing
group :development, :test do 
       gem 'rspec'
       gem 'rspec-rails', '>=2.5.0'       
       gem 'generator_spec'
       gem 'cucumber-rails'
       gem 'database_cleaner'  
       gem 'capybara'
       gem 'webrat'
       gem 'aruba'
end

gem 'jettywrapper', '>= 1.2.0'
gem \"devise\"
" > Gemfile

bundle install --local &> /dev/null 
bundle update
# If a local install fails, try a full install.
if [ "$?" -ne "0" ]
then
  bundle install
fi
check_errs $? "Bundle install failed." 
rails generate blacklight -d
check_errs $?  "Blacklight generator failed" 
bundle exec rake db:migrate
check_errs $? "Rake Migration failed" 
rails g cucumber:install &> /dev/null 
jetty_zip="/tmp/bl_jetty_3_5_0.zip"
if [ ! -f $jetty_zip ]
then
  curl -L https://github.com/projectblacklight/blacklight-jetty/zipball/v3.5.0 > $jetty_zip
  check_errs $? "Jetty file does not exist, and cannot be downloaded."
fi
rails g blacklight:jetty test_jetty -e test -d $jetty_zip
  check_errs $? "Jetty setup failed."
rm public/index.html
bundle exec rake solr:marc:index_test_data RAILS_ENV=test
bundle exec rake blacklight:hudson
check_errs $? "Tests failed." 
benchmark
