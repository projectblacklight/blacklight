module Blacklight::Syndetics
  
  class Bookcovers
    
    attr :options
    
    def initialize(options={})
      options[:first] = true unless options.has_key?(:first)
      @options=options
    end
    
    #
    # find :isbn=>[123459087,12358971625]
    #
    def find(keys)
      raise ':isbn is required and is the only supported key type' unless keys[:isbn].is_a?(Array)
      data=[]
      keys[:isbn].each do |isbn|
        url = "http://syndetics.com/index.aspx?isbn=#{isbn}/mc.jpg" #"&client=sirsi&type=rw12"
        next unless (binary = Blacklight::Utils.valid_image_url?(url))
        data << {
          :source_data=>binary,
          :source_url=>url,
          :source=>:syndetics,
          :key_type=>:isbn,
          :key=>isbn,
          :ext=>'.jpg'
        }
        break if @options[:first]
      end
      data.empty? ? nil : data
    end
    
  end
  
  #
  #
  #
  class Review
    #
    #
    #
    SOURCE_TYPES={
      :preview=>'PWREVIEW',
      :summary=>'SUMMARY',
      :toc=>'TOC',
      :bnatoc=>'BNATOC',
      :fiction=>'FICTION',
      :dbchapter=>'DBCHAPTER',
      :ljreview=>'LJREVIEW',
      :sljreview=>'SLJREVIEW',
      :chreview=>'CHREVIEW',
      :anotes=>'ANOTES',
      :blreview=>'BLREVIEW',
      :doreview=>'DOREVIEW',
      :reviews=>'REVIEWS'
    }
    
    def initialize(client_id=nil)
      @client_id=client_id
    end
    
    #
    # http://syndetics.com/index.aspx?isbn=12358971625/CHREVIEW.HTML
    #
    def find_by_isbn(isbn, config={})
      opts={
        :source_type=>:preview,
        :source_format=>:xml,
        :type=>nil
      }.merge!(config)
      source = resolve_source(opts[:source_type], opts[:source_format])
      url = "http://syndetics.com/index.aspx?isbn=#{isbn}/"
      url += "#{source}&client=#{@client_id}&type=#{opts[:type]}"
      uri=URI.parse(URI.encode(url))
      Net::HTTP.get(uri)
    end
    
    protected
      def resolve_source(source_type, source_format)
        "#{SOURCE_TYPES[source_type]}.#{source_format.to_s.upcase}"
      end
  end
  
end