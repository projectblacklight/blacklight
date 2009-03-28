require 'rubygems'
gem 'flexmock'

require 'test/unit'
require 'flexmock/test_unit'
require File.dirname(__FILE__) + '/../lib/yahoo-music'

include Yahoo::Music

def fixture(_filename)
  File.open(File.dirname(__FILE__) + '/fixtures/%s.xml' % _filename ).read
end