module Blacklight::Google
  
  class Bookcovers
    
    attr :options
    
    def initialize(options={})
      options[:first] = true unless options.has_key?(:first)
      @options=options
    end
    
    def find(keys)
      data=[]
      q = create_query(keys)
      cb='CALLBACK'
      url = "http://books.google.com/books?jscmd=viewapi&bibkeys=#{q}&callback=#{cb}&zoom=0"
      uri = URI.parse(url)
      body = Net::HTTP.start(uri.host) {|http| http.get(uri.path + '?' + uri.query)}.body
      return nil unless body =~ /thumbnail_url/
      # remove the callback stuff
      json = body.sub(/^#{cb}\(/,'').sub(/\);$/,'')
      # loop through each item
      ActiveSupport::JSON.decode( json ).each_pair do |bibkey,item|
        next if item['thumbnail_url'].to_s.empty?
        # might be able to change the zoom param in the thumbnail_url to 0 for larger images
        binary = Blacklight::Utils.valid_image_url?(item['thumbnail_url'])
        next if ! binary # sometimes google returns an error page!
        data << {
          :source_data=>binary,
          :source_url=>item['thumbnail_url'],
          :source=>:google,
          :key_type=>item['bib_key'].split(':').first.downcase.to_sym,
          :key=>item['bib_key'].sub(/^.+\:/, ''),
          :ext=>'.jpg'
        }
        break if @options[:first]
      end
      data
    end
    
    def create_query(input)
      [:isbn,:oclc,:lccn].collect do |type|
        next if input[type].to_s.empty?
        input[type].collect{|v|"#{type.to_s.upcase}:#{v}"}.join(',')
      end.compact.join(',')
    end
    
  end
  
end