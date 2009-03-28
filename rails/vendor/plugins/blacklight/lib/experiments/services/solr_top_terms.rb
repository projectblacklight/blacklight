require 'net/http'
require 'rubygems'
require 'json'

# This class is used for fetching the top terms using the solr admin/luke handler
# If returns a paired array like:
# [term_1, term_1_hits, term_2, term_2_hits]
# 
# The fetch method also caches the results in a serialized ruby format
# 
# EXAMPLE:
# 
# url = 'http://localhost:8983/solr/admin/luke'
# solr_geo = Blacklight::SolrTopTerms.new(url, 'regions_facet', :num_terms=>1000)
# puts solr_geo.fetch(optional_name_of_cache_file)
#

class Blacklight::SolrTopTerms
  
  attr :solr_luke_url
  attr :field
  attr :opts
  
  def initialize(solr_luke_url, field, opts={})
    @solr_luke_url = solr_luke_url
    @field = field.to_s
    @opts = {:timeout=>480.0, :num_terms=>0}.merge(opts)
  end
  
  def fetch(cache_file=nil)
    cache_file ||= 'serialized_top_terms.cache'
    if ! File.exists?(cache_file)
      log 'loading region_facet values from solr'
      cache!(regions_from_solr, cache_file)
    else
      log 'loading region_facet values from cache'
      load_from_cache(cache_file)
    end
  end
  
  protected
  
  def log(msg)
    puts msg
  end
  
  def regions_from_solr
    uri = URI.parse(@solr_luke_url)
    http = Net::HTTP.new(uri.host, uri.port)
    http.read_timeout = @opts[:timeout]
    r = http.get(uri.path + "?numTerms=#{@opts[:num_terms]}&fl=#{@field}&wt=ruby")
    if r.code=='200'
      ruby = eval(r.body)
      ruby['fields'][@field]['topTerms'] if ruby['fields'] and ruby['fields'][@field]
    else
      raise 'Solr HTTP Error: ' + r.to_s
    end
  end
  
  def cache!(data, file)
    File.open(file, File::CREAT|File::WRONLY) do |f|
      f.puts Marshal.dump(data)
    end
    data
  end
  
  def load_from_cache(file)
    Marshal.load(File.read(file))
  end
  
end