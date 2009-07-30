module Blacklight::Wikipedia
  
  class Lookup
    #
    #
    #
    def initialize(config={})
      @options={
        :format=>:json,
        :base_url=>"http://en.wikipedia.org/w/api.php"
      }.merge!(config)
    end

    #
    # Call Wikipedia's "query" action
    #
    def query(value, options={})
      params={
        :action=>:query,
        :prop=>:revisions,
        :rvprop=>:content,
        :format=>@options[:format],
        :titles=>value
      }.merge!(options)
      call_wikipedia(params)
    end
    
    protected
      
      #
      #
      #
      def call_wikipedia(params={})
        url = @options[:base_url] + '?' + hash_to_query(params)
        Net::HTTP.get(URI.parse(URI.encode(url)))
      end

      #
      # using an empty array to "inject" into...
      # loop through each value in the hash, creating a string using:
      #   key=val (v.first.to_s=v.last.to_s)
      # then pushing each string into the array
      # and finally joining them all using an "&" :)
      #
      def hash_to_query(hash)
        hash.inject([]) {|acc,v|acc << "#{v.first.to_s}=#{v.last.to_s}"}.join('&')
      end
  end
  
end