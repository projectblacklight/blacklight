require 'rubygems'
require 'curb'

class RSolr::HTTPClient::Adapter::Curb
  
  include RSolr::HTTPClient::Util
  
  attr :uri
  attr :connection
  
  def initialize(url)
    @uri = URI.parse(url)
    @connection = ::Curl::Easy.new
  end
  
  def get(path, params={})
    @connection.url = _build_url(path, params)
    @connection.multipart_form_post = false
    @connection.perform
    create_http_context(path, params)
  end
  
  def post(path, data, params={}, headers={})
    @connection.url = _build_url(path, params)
    @connection.headers = headers
    @connection.http_post(data)
    create_http_context(path, params, data, headers)
  end
  
  protected
  
  def create_http_context(path, params, data=nil, headers={})
    {
      :status_code=>@connection.response_code.to_i,
      :url=>@connection.url,
      :body=>@connection.body_str,
      :path=>path,
      :params=>params,
      :data=>data,
      :headers=>headers
    }
  end
  
  def _build_url(path, params={})
    url = @uri.scheme + '://' + @uri.host
    url += ':' + @uri.port.to_s if @uri.port
    url += @uri.path + path
    build_url(url, params, @uri.query) # build_url is coming from RSolr::HTTPClient::Util
  end
  
end