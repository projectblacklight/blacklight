#!/bin/bash
# test.sh
# Create a default rails appliaction, install blacklight, and run all the tests.

#If null or empty, use default valueRAILS
JETTY_URL=${JETTY_URL:-"https://github.com/projectblacklight/blacklight-jetty/zipball/v4.0.0"}

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


if [[  $# -gt 0 ]]
then
# Make certain rvm will work correctly.
# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  # First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  # Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  echo "WARNING: An RVM installation was not found.\n"
  exit 1
fi

rvm use "$@" --create
check_errs $? "rvm failed.  please run 'rvm install $@', and then re-run these tests."
fi

rails new test_app

cd test_app

if [ -e public/index.html ]; then
  rm public/index.html
fi

echo "
platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3'
  gem 'mediashelf-loggable', '>= 0.4.8'
  gem 'therubyrhino'
end

platforms :ruby do
 gem 'sqlite3'
 gem 'execjs'
 gem 'therubyracer', '~> 0.10.2'
end

gem 'blacklight', :path => '../../'
gem 'jquery-rails'

# For testing
group :development, :test do
  gem 'rspec-rails', '~> 2.12.0'
end

group :test do
  gem 'generator_spec'
  gem 'cucumber-rails', :require => false
  gem 'database_cleaner'
  if defined? :JRUBY_VERSION
    gem 'capybara', '~> 1.0'
  else
    gem 'capybara'
  end
  gem 'rcov', :platform => :mri_18
  gem 'simplecov', :platform => :mri_19
  gem 'simplecov-rcov', :platform => :mri_19
end

gem 'jettywrapper', '>= 1.2.0'
" >> Gemfile

export BUNDLE_GEMFILE=`pwd`/Gemfile

bundle install
check_errs $? "Bundle install failed."

rails generate blacklight -d
check_errs $?  "Blacklight generator failed"

bundle exec rake db:migrate RAILS_ENV=test
check_errs $? "Rake Migration failed"

rails g cucumber:install &> /dev/null

rails g blacklight:test_support

jetty_zip=$( JETTY_URL=$JETTY_URL ruby -e 'puts "/tmp/blacklight_jetty_#{ENV["JETTY_URL"].split("/").last}"')
if [ ! -f $jetty_zip ]
then
  curl -L $JETTY_URL -o $jetty_zip
  check_errs $? "Jetty file does not exist, and cannot be downloaded."
fi

rails g blacklight:jetty test_jetty -e test -d $jetty_zip
check_errs $? "Jetty setup failed."

rake jetty:start RAILS_ENV=test
bundle exec rake solr:marc:index_test_data RAILS_ENV=test
rake jetty:stop RAILS_ENV=test
sleep 2

bundle exec rake blacklight:hudson RAILS_ENV=test
check_errs $? "Tests failed."

benchmark
