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

    # Attempt to shut down jetty, if set.
    if [ $jetty_pid ] 
    then
	kill $jetty_pid
    fi
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
gem install --no-rdoc --no-ri 'rails'
gem install --no-rdoc --no-ri 'bundler'
gem install --no-rdoc --no-ri 'devise'
rails new test_app
cd test_app
echo "
source 'http://rubygems.org'

gem 'rails', '>=3.0.4'
platforms :jruby do
  gem 'jruby-openssl'
  gem 'activerecord-jdbcsqlite3-adapter'
  gem 'jdbc-sqlite3'
end
platforms :ruby do
 gem 'sqlite3-ruby', :require => 'sqlite3'
end
gem 'blacklight', :path => '../../'

# For testing
group :development, :test do 
       gem 'rspec'
       gem 'rspec-rails', '~>2.5.0'       
       gem 'generator_spec'
       gem 'cucumber-rails'
       gem 'database_cleaner'  
       gem 'capybara'
       gem 'webrat'
       gem 'aruba'
end
" > Gemfile

bundle install --local &> /dev/null 
# If a local install fails, try a full install.
if [ "$?" -ne "0" ]
then
  bundle install
fi
check_errs $? "Bundle install failed." 
rails generate blacklight -d
check_errs $?  "Blacklight generator failed" 
rake db:migrate
check_errs $? "Rake Migration failed" 
rails g cucumber:install &> /dev/null 
jetty_zip="/tmp/bl_jetty.zip"
if [ ! -f $jetty_zip ]
then
  curl -L https://github.com/projectblacklight/blacklight-jetty/zipball/v1.4.1-1 > $jetty_zip
  check_errs $? "Jetty file does not exist, and cannot be downloaded."
fi
rails g blacklight:jetty test_jetty -e test -d $jetty_zip
  check_errs $? "Jetty setup failed."
rm public/index.html
rake solr:marc:index_test_data RAILS_ENV=test
cd test_jetty
java -Djetty.port=8888 -Dsolr.solr.home=./solr -jar start.jar &> /dev/null &
jetty_pid=$!
cd ..
bundle exec rake blacklight:spec
check_errs $? "Rpec Tests failed." 
bundle exec rake blacklight:cucumber
check_errs $? "Cucumber Tests failed." 
benchmark