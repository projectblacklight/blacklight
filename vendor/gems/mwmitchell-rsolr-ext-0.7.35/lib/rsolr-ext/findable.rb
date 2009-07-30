# Findable can be mixed into whatever RSolr.connect returns.
# RSolr::Ext.connect() does this for you.
# Findable makes querying solr easier by providing a simple #find method.
#
# The #find method behaves differently depending on what you send in.
#
# The first argument can be either a symbol (:all, :first)
# OR
# a solr params hash
# OR
# a string that will be used for the query.
#
# If the first argument is a symbol, the second is used for solr params or the query.
# 
# If the first argument is :first, then only a single document is returns (:rows=>0)
# If the first argument is :all, then all documents are returned
# 
# If a hash is used for solr params, all of the normal RSolr::Ext::Request::Standard
# mappings are available (everything else gets passed to solr).
# 
# If a string is used, it's set to the :q param.
#
# The last argument (after the query or solr params) is used for finding options.
# The following opts are allowed:
# :include_response - false is default - whether or not to return the whole solr response or just the doc(s)
# :handler  - nil is default - the request path (/select or /search etc.)
module RSolr::Ext::Findable
  
  # Examples:
  # find 'jefferson' # q=jefferson - all docs
  # find :first, 'jefferson' # q=jefferson&rows=1 - first doc only
  # find 'jefferson', :phrase_filters=>{:type=>'book'} # q=jefferson&fq=type:"book" - all docs
  # find {:q=>'something'}, :include_response=>true # q=something -- the entire response
  def find(*args, &blk)
    mode, solr_params, opts = extract_find_opts!(*args)
    
    opts[:include_response] ||= true
    
    solr_params[:rows] = 1 if mode == :first
    valid_solr_params = RSolr::Ext.map_params(solr_params)
    
    response = opts[:handler] ? send_request(opts[:handler], valid_solr_params) : select(valid_solr_params)
    return response if response.is_a?(String)
    
    response = RSolr::Ext::wrap_response(response)
    
    if block_given? and response['response']['docs']
      # yield each doc if a block is given
      response['response']['docs'].each_with_index do |doc,i|
        response['response']['docs'][i] = yield(doc)
      end
    end
    if opts[:include_response] == true
      response
    else
      if mode == :first
        # return only one doc
        response['response']['docs'].first
      else
        # return all docs
        response['response']['docs']
      end
    end
  end
  
  # find_by_id(10, :handler=>'catalog')
  # find_by_id(:id=>10)
  def find_by_id(id, solr_params={}, opts={}, &blk)
    if id.respond_to?(:each_pair)
      solr_params = id
    else
      solr_params[:phrases] ||= {}
      solr_params[:phrases][:id] = id.to_s
    end
    self.find(:first, solr_params, opts, &blk)
  end
  
  protected
  
  def extract_find_opts!(*args)
    mode = :all
    valid_modes = [:all, :first]
    if args[0].is_a?(Symbol)
      mode = valid_modes.include?(args[0]) ? args.shift : raise("Invalid find mode; should be :first or :all")
    end
    # extract solr params
    solr_params = args.shift
    unless solr_params.respond_to?(:each_pair)
      solr_params = {:q=>solr_params.to_s}
    end
    # extract options
    opts = args.shift || {}
    [mode, solr_params, opts]
  end
  
end