require 'rubygems'
require 'net/http'
require 'active_support'

module Blacklight::Yahoo
  
  class << self
    attr_accessor :app_id
    attr_accessor :service_base_url
  end
  
  @app_id = 'YahooDemo'
  @service_base_url = 'http://search.yahooapis.com'
  
  class Music
    
    def audio_search_service_base_url(type, params={})
      url = Blacklight::Yahoo.service_base_url + '/AudioSearchService/V1/' + type
      url += "?appid=#{Blacklight::Yahoo.app_id}&results=50&type=all&output=json"
    end
    
    def send_request(url)
      uri = URI.parse(url)
      data = Net::HTTP.get_response(uri).body
      ActiveSupport::JSON.decode(data)
    end
    
    def search(query)
      url = Blacklight::Yahoo.service_base_url + "/release/v1/list/search/all/#{URI.encode(query)}/"
      url += "?response=main,tracks,artists"
      url += "&appid=#{Blacklight::Yahoo.app_id}"
      url += "&output=json"
      send_request url
    end
    
    # finds the first item in the result and returns the Thumbnail['Url'] if present
    def album_thumb_by_artist_and_title(artist, title)
      yahoo_response = song_search_by_artist_and_title(artist, title)
      item_with_thumb=nil
      if yahoo_response['ResultSet'] and yahoo_response['ResultSet']['Result']
        item_with_thumb = yahoo_response['ResultSet']['Result'].detect{|item|item.has_key?('Thumbnail')}
      end
      item_with_thumb['Thumbnail']['Url'] if item_with_thumb
    end
    
    def song_search_by_artist_and_title(artist, title)
      url = audio_search_service_base_url('songSearch')
      url += "&album=#{URI.encode(title)}"
      url += "&author=#{URI.encode(artist)}"
      send_request(url)
    end
    
    def album_by_artist_and_title(artist, title)
      url = audio_search_service_base_url('albumSearch')
      url += "&album=#{URI.encode(title)}"
      url += "&author=#{URI.encode(artist)}"
      send_request(url)
    end
    
  end
  
end