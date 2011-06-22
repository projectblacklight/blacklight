#!/bin/bash
# test.sh
# Create a default rails appliaction, install blacklight, and run all the tests.

check_errs()
{
  # Function. Parameter 1 is the return code
  # Para. 2 is text to display on failure.
  if [ "${1}" -ne "0" ]; then
    echo "ERROR # ${1} : ${2}"
    # as a bonus, make our script exit with the right error code.
    exit ${1}
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
\# Load RVM into a shell session *as a function*
if [[ -s "$HOME/.rvm/scripts/rvm" ]] ; then
  \# First try to load from a user install
  source "$HOME/.rvm/scripts/rvm"
elif [[ -s "/usr/local/rvm/scripts/rvm" ]] ; then
  \# Then try to load from a root install
  source "/usr/local/rvm/scripts/rvm"
else
  printf "ERROR: An RVM installation was not found.\n"
  exit 1
fi

# Switch over to the currect ruby version
case "$@" in

    "jruby")
	echo "running Jruby Tests"	
	rvm jruby-1.6.2
	check_errs $? "rvm failed.  try rvm install jruby-1.6.2, and then re-run these tests." 
	jruby -S rails new test_app -m http://jruby.org/rails3.rb
	;;

    "1.9.2")
	echo "running tests in 1.9.2"
	rvm 1.9.2
	check_errs $? "rvm failed.  try rvm install 1.9.2, and then re-run these tests." 
	rails new test_app
	;;

    "1.8.7")
	echo "running tests in 1.8.7"
	rvm 1.8.7
	check_errs $? "rvm failed.  try rvm install 1.8.7, and then re-run these tests." 
	rails new test_app
	;;

    * )
	echo "unknown test type.  Please specify jruby, 1.9.2, or 1.8.7"
	exit 1
esac

cd test_app
rm Gemfile
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
gem 'blacklight', :path => '../../../'

# For testing
group :development, :test do 
       gem 'rspec'
       gem 'rspec-rails', '~>2.5.0'       
       gem 'cucumber-rails'
       gem 'database_cleaner'  
       gem 'capybara'
       gem 'webrat'
       gem 'aruba'
end
" >> Gemfile

bundle install --local
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
rails g cucumber:install
rails g blacklight:jetty test_jetty -e test
rm public/index.html
rake solr:marc:index_test_data RAILS_ENV=test
cd test_jetty
java -Djetty.port=8888 -Dsolr.solr.home=./solr -jar start.jar &> /dev/null &
jetty_pid=$!
cd ..
rake blacklight:spec
check_errs $? "rspec tests failed" 
rake blacklight:cucumber
check_errs $? "Cucumber tests failed"
# Shutdown jetty
kill $jetty_pid