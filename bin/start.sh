#!/usr/bin/env bash

rm .internal_test_app/tmp/pids/server.pid 2> /dev/null
bundle install
bundle exec rake blacklight:server["-p 3000 -b '0.0.0.0'"]
