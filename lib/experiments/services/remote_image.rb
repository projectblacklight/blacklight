require "fileutils"

module Blacklight::RemoteImage
  
  #
  #
  #
  class Finder
    
    attr :options
    attr :cache
    attr :finders
    
    def initialize(options={})
      options[:first] = true unless options.has_key?(:first)
      @options=options
      if @options[:use_cache]==true
        cache_opts = {
          :url=>options[:cache_url],
          :dir=>options[:cache_dir],
          :first=>options[:first]
        }
        @cache = Blacklight::RemoteImage::Cache.new(cache_opts)
      end
      @finders = []
    end
    
    #
    #
    #
    def add_finder(source, finder)
      @finders << {:source=>source, :finder=>finder}
    end
    
    #
    # {:isbn=>[1234567812, 9876543214]}, '.jpg')
    #
    def find(keys, ext='.*')
      if @cache and cached = @cache.find(@finders.map{|v|v[:source]}, keys, ext)
        return cached
      end
      data=[]
      finders.each do |f|
        images = f[:finder].find(keys)
        next if images.nil?
        images.each{ |image| @cache.store!(image) } if @cache
        data += images
        break if @options[:first]==true
      end
      return data unless data.empty?
      unless @options[:default_image_url].nil?
        [{
          :source=>'',
          :key_type=>'',
          :key=>'',
          :url=>@options[:default_image_url]
        }]
      end
    end
    
  end
  
  #
  #
  #
  class Cache
    
    attr :options
    
    def initialize(options={})
      raise ":url option required" if options[:url].nil?
      raise ":dir option required" if options[:dir].nil?
      options[:first] = true unless options.has_key?(:first)
      @options=options
    end
    
    #
    # returns an array of Blacklight::Image instances
    # find([:google, :syndetics], {:isbn=>[1234567812, 9876543217]})
    #
    def find(sources, keys, ext='.*')
      images=[]
      # look through the cache dir using the source and keys
      keys.each_pair do |key_type,key_values|
        key_values.each do |key_value|
          sources.each do |source|
            path = build_path(:dir, source, key_type, key_value, ext)
            Dir[path].each do |file|
              ext = File.extname(file)
              url = build_path(:url, source, key_type, key_value, ext)
              images << {:source=>source, :key_type=>key_type, :key=>key_value, :file=>file, :url=>url, :ext=>ext}
              return images if @options[:first]==true
            end
          end
        end
      end
      images.empty? ? nil : images
    end
    
    def store!(image)
      # :data is set ONLY when the image has been collected from a source finder
      return unless image[:source_data]
      image[:file] = build_path(:dir, image[:source], image[:key_type], image[:key], image[:ext])
      # Create the directory
      FileUtils.mkdir_p File.dirname(image[:file])
      # Fetch the binary from the url and store it in the file, close, and we're done!
      File.open(image[:file], File::WRONLY|File::CREAT) do |f|
        f.puts image[:source_data]
      end
      # reset the url
      image[:url] = build_path(:url, image[:source], image[:key_type], image[:key], image[:ext])
    end
    
    #
    # build_path(:dir, :syndetics, :isbn, 1234567884) == full path
    # build_path(:url, :library_thing, :isbn, 1234567884) == full url
    #
    def build_path(path_type, source, key_type, value, ext)
      raise "Invalid type" unless [:dir,:url].include?(path_type)
      File.join(@options[path_type], source.to_s, "#{key_type}.#{value}#{ext}")
    end
    
  end
  
end