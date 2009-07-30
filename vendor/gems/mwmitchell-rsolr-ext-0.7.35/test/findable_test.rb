require 'test_unit_test_case'
require File.join(File.dirname(__FILE__), '..', 'lib', 'rsolr-ext')
require 'helper'

class RSolrExtFindableTest < Test::Unit::TestCase
  
  test 'RSolr::connect' do
    connection = RSolr::Ext.connect
    assert connection.respond_to?(:find)
  end
  
end