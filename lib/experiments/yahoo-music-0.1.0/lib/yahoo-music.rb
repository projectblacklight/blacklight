%w{rubygems cgi hpricot activesupport}.each { |x| require x }

$:.unshift(File.dirname(__FILE__)) unless
  $:.include?(File.dirname(__FILE__)) || $:.include?(File.expand_path(File.dirname(__FILE__)))

require 'rest'
require 'yahoo-music/base'
require 'yahoo-music/version'

require 'yahoo-music/artist'
require 'yahoo-music/category'
require 'yahoo-music/release'
require 'yahoo-music/review'
require 'yahoo-music/track'
require 'yahoo-music/video'

module Yahoo
  module Music
    LOCALE      = "us"
    API_URL     = "http://#{LOCALE}.music.yahooapis.com/"
    API_VERSION = 'v1'
    
    class << self
      def app_id=(_id)
        Yahoo::Music::Base::connection = REST::Connection.new(API_URL, 'app_id' => _id)
      end
    end
  end
end