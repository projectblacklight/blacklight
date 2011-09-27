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

cd tmp/test_app
cd test_jetty
java -Djetty.port=8888 -Dsolr.solr.home=./solr -jar start.jar &> /dev/null &
jetty_pid=$!
cd ..
bundle exec rake blacklight:spec
check_errs $? "Rpec Tests failed." 
bundle exec rake blacklight:cucumber
check_errs $? "Cucumber Tests failed." 
benchmark
