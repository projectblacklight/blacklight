# don't run this test in jruby,
# the curb gem is a c extension based gem, jruby has no support for this
unless defined?(JRUBY_VERSION)

  require 'helper'
  require 'http_client/test_methods'

  class CurbTest < RSolrBaseTest
  
    def setup
      @c ||= RSolr::HTTPClient::Connector.new(:curb).connect(URL)
    end
  
    include HTTPClientTestMethods
  
  end
  
end