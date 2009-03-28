module Blacklight::Utils
  
  class << self
    
    def valid_image_url?(url, min_content_length=90)
      res = fetch_url(url)
      ok = (res.code=='200' and res.body.length >= min_content_length)
      ok ? res.body : nil
    end
    
    def fetch_url(url)
      RAILS_DEFAULT_LOGGER.info "***** URL IS: #{url}"
      url = URI.parse(url)
      http = Net::HTTP.new(url.host,url.port)
      http.use_ssl = url.port==443
      http.get(url.path + '?' + url.query.to_s)
    end
    
    def valid_isbn?(isbn, c_map = '0123456789X')
      sum = 0
      isbn[0..-2].scan(/\d/).each_with_index do |c,i|
        sum += c.to_i*(i+1)
      end
      isbn[-1] == c_map[sum % c_map.length]
    end
    
  end
  
end