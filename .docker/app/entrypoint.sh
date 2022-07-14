#!/usr/bin/env bash
set -e

rm -f /app/.internal_test_app/tmp/pids/server.pid
bundle install
exec bundle exec rake blacklight:server["-p 3000 -b 0.0.0.0"]
