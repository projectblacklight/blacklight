raise "JRuby Required" unless defined?(JRUBY_VERSION)

require 'java'

#
# Connection for JRuby + DirectSolrConnection
#
class RSolr::Adapter::Direct
  
  include RSolr::HTTPClient::Util
  
  attr_accessor :opts, :home_dir
  
  # required: opts[:home_dir] is absolute path to solr home (the directory with "data", "config" etc.)
  # opts must also contain either
  #   :dist_dir => 'absolute path to solr distribution root
  # or
  #   :jar_paths => ['array of directories containing the solr lib/jars']
  # OTHER OPTS:
  #   :select_path => 'the/select/handler'
  #   :update_path => 'the/update/handler'
  def initialize(opts, &block)
    @home_dir = opts[:home_dir].to_s
    opts[:data_dir] ||= File.join(@home_dir, 'data')
    if opts[:dist_dir] and ! opts[:jar_paths]
      # add the standard lib and dist directories to the :jar_paths
      opts[:jar_paths] = [File.join(opts[:dist_dir], 'lib'), File.join(opts[:dist_dir], 'dist')]
    end
    @opts = opts
  end
  
  # loads/imports the java dependencies
  # sets the @connection instance variable
  def connection
    @connection ||= (
      require_jars(@opts[:jar_paths]) if @opts[:jar_paths]
      import_dependencies
      DirectSolrConnection.new(@home_dir, @opts[:data_dir], nil)
    )
  end
  
  def close
    if @connection
      @connection.close
      @connection=nil
    end
  end
  
  # send a request to the connection
  # request '/update', :wt=>:xml, '</commit>'
  def send_request(path, params={}, data=nil)
    data = data.to_xml if data.respond_to?(:to_xml)
    url = build_url(path, params)
    begin
      body = connection.request(url, data)
    rescue
      raise RSolr::RequestError.new($!.message)
    end
    {
      :body=>body,
      :url=>url,
      :path=>path,
      :params=>params,
      :data=>data,
    }
  end
  
  protected
  
  # do the java import thingy
  def import_dependencies
    import org.apache.solr.servlet.DirectSolrConnection
  end
  
  # require the jar files
  def require_jars(paths)
    paths = [paths] unless paths.is_a?(Array)
    paths.each do |path|
      jar_pattern = File.join(path,"**", "*.jar")
      Dir[jar_pattern].each {|jar_file| require jar_file}
    end
  end
  
end