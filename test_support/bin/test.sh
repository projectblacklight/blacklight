#!/bin/bash
# test.sh
# Create a default rails appliaction, install blacklight, and run all the tests.

#If null or empty, use default value
RAILS_VERSION=${RAILS_VERSION:-3.2}
JETTY_URL=${JETTY_URL:-"https://github.com/projectblacklight/blacklight-jetty/zipball/v3.5.0"}

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

if ! gem query -n rails -v $RAILS_VERSION --installed > /dev/null; then
  gem install --no-rdoc --no-ri 'rails' -v $RAILS_VERSION
fi

if ! gem query -n bundler -v ">=1.0" --installed > /dev/null; then
  gem install --no-rdoc --no-ri 'bundler'
fi

rails new test_app
cd test_app
rm public/index.html

echo "
platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3'
  gem 'mediashelf-loggable', '>= 0.4.8'
  gem 'therubyrhino'
end

platforms :ruby do
 gem 'sqlite3-ruby', :require => 'sqlite3'
 gem 'execjs'
 gem 'therubyracer'
end

gem 'blacklight', :path => '../../'
gem 'jquery-rails'

group :assets do
  gem 'compass', '0.12.alpha.2'
end


# For testing
group :development, :test do 
  gem 'rspec'
  gem 'rspec-rails'
  gem 'generator_spec'
  gem 'cucumber-rails'
  gem 'database_cleaner'
  gem 'capybara'
end

gem 'jettywrapper', '>= 1.2.0'
gem \"devise\"
" >> Gemfile

bundle install
check_errs $? "Bundle install failed." 

rails generate blacklight -d
check_errs $?  "Blacklight generator failed" 

bundle exec rake db:migrate
check_errs $? "Rake Migration failed" 

rails g cucumber:install &> /dev/null 


jetty_zip=$( echo $JETTY_URL | awk '{split($0,a,"/"); print "/tmp/blacklight_jetty_"a[length(a)]}')
if [ ! -f $jetty_zip ]
then
  curl -L $JETTY_URL -o $jetty_zip
  check_errs $? "Jetty file does not exist, and cannot be downloaded."
fi

rails g blacklight:jetty test_jetty -e test -d $jetty_zip
check_errs $? "Jetty setup failed."

bundle exec rake solr:marc:index_test_data RAILS_ENV=test

bundle exec rake blacklight:hudson
check_errs $? "Tests failed." 

benchmark
