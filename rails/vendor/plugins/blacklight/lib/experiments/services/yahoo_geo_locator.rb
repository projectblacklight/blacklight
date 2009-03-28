require 'net/http'
require 'rubygems'
require 'json'

#
# app_id = 'your-app-id'
# y = Blacklight::YahooGEOLocator.new(app_id)
#
# Can also set global app_id:
# Blacklight::YahooGEOLocator.app_id = 'app_id
#
# results = y.locate('United States')
#
# "results" is a Hash, and look like:
#

=begin
{
  "places"=>{
    "place"=>[
      {
        "boundingBox"=>{
          "northEast"=>{
            "latitude"=>72.896057,
            "longitude"=>-66.687943
          },
          "southWest"=>{
            "latitude"=>18.910839,
            "longitude"=>-167.276413
          }
        },
        "postal"=>"",
        "name"=>"United States",
        "uri"=>"http://where.yahooapis.com/v1/place/23424977",
        "placeTypeName"=>"Country",
        "woeid"=>23424977,
        "country attrs"=>{
          "code"=>"US",
          "type"=>"Country"
        },
        "placeTypeName attrs"=>{
          "code"=>12
        },
        "centroid"=>{
          "latitude"=>48.890652,
          "longitude"=>-116.982178
        },
        "country"=>"United States",
        "admin1"=>"",
        "lang"=>"en-US",
        "locality1"=>"",
        "admin2"=>"",
        "locality2"=>"",
        "admin3"=>""
    }],
    "total"=>1,
    "start"=>0,
    "count"=>1
  }
}
=end

class Blacklight::YahooGEOLocator
  
  attr :app_id
  attr :opts
  
  class << self; attr_accessor :app_id; end
  @app_id=nil
  
  def initialize(yahoo_app_id=nil, opts={})
    @app_id = (yahoo_app_id || self.class.app_id)
    @opts = {:timeout=>480.0}.merge(opts)
  end
  
  def locate(keywords)
    uri = URI.parse('http://where.yahooapis.com/v1/')
    http = Net::HTTP.new(uri.host)
    http.read_timeout = @opts[:timeout]
    path = uri.path + 'places.q(' + CGI.escape(keywords.to_s) + ')' + "?appid=#{@app_id}&format=json"
    response = http.get(path)
    if response.code=='200'
      JSON.parse(response.body)
    else
      raise response.body
    end
  end
  
end