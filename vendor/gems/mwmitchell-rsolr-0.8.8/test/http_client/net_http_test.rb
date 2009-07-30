require 'helper'
require 'http_client/test_methods'

class NetHTTPTest < RSolrBaseTest
  
  def setup
    @c ||= RSolr::HTTPClient::Connector.new(:net_http).connect(URL)
  end
  
  include HTTPClientTestMethods
  
end