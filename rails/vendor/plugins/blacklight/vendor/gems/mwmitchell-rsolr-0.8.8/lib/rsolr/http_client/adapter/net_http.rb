require 'net/http'

class RSolr::HTTPClient::Adapter::NetHTTP
  
  include RSolr::HTTPClient::Util
  
  attr :uri
  attr :connection
  
  def initialize(url)
    @uri = URI.parse(url)
    @connection = Net::HTTP.new(@uri.host, @uri.port)
  end
  
  def get(path, params={})
    url = _build_url(path, params)
    net_http_response = @connection.get(url)
    create_http_context(net_http_response, url, path, params)
  end
  
  def post(path, data, params={}, headers={})
    url = _build_url(path, params)
    net_http_response = @connection.post(url, data, headers)
    create_http_context(net_http_response, url, path, params, data, headers)
  end
  
  protected
  
  def create_http_context(net_http_response, url, path, params, data=nil, headers={})
    full_url = "#{@uri.scheme}://#{@uri.host}"
    full_url += @uri.port ? ":#{@uri.port}" : ''
    full_url += url
    {
      :status_code=>net_http_response.code.to_i,
      :url=>full_url,
      :body=>net_http_response.body,
      :path=>path,
      :params=>params,
      :data=>data,
      :headers=>headers
    }
  end
  
  def _build_url(path, params={})
    build_url(@uri.path + path, params, @uri.query) # build_url is coming from RSolr::HTTPClient::Util
  end
  
end