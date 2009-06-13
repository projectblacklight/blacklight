class RSolr::Connection
  
  attr_reader :adapter, :opts
  
  # "adapter" is instance of:
  #   RSolr::Adapter::HTTP
  #   RSolr::Adapter::Direct (jRuby only)
  def initialize(adapter, opts={})
    @adapter = adapter
    @opts = opts
  end
  
  # Send a request to a request handler using the method name.
  # This does not handle data, only selects
  def method_missing(method_name, params)
    send_request("/#{method_name}", map_params(params))
  end
  
  # send a request to the "select" handler
  def select(params)
    send_request('/select', map_params(params))
  end
  
  # sends data to the update handler
  # data can be a string of xml, or an object that returns xml from its #to_xml method
  def update(data, params={})
    send_request('/update', map_params(params), data)
  end
  
  # send request solr
  # params is hash with valid solr request params (:q, :fl, :qf etc..)
  #   if params[:wt] is not set, the default is :ruby
  #   if :wt is something other than :ruby, the raw response body is used
  #   otherwise, a simple Hash is returned
  #   NOTE: to get raw ruby, use :wt=>'ruby' <- a string, not a symbol like :ruby  
  #
  #
  def send_request(path, params={}, data=nil)
    response = @adapter.send_request(path, map_params(params), data)
    adapt_response(response)
  end
  
  # allow #request to be used like send_request
  alias_method :request, :send_request
  
  # 
  # single record:
  # solr.update(:id=>1, :name=>'one')
  #
  # update using an array
  # solr.update([{:id=>1, :name=>'one'}, {:id=>2, :name=>'two'}])
  #
  def add(doc, &block)
    update message.add(doc, &block)
  end
  
  # send </commit>
  def commit
    update message.commit
  end
  
  # send </optimize>
  def optimize
    update message.optimize
  end
  
  # send </rollback>
  # NOTE: solr 1.4 only
  def rollback
    update message.rollback
  end
  
  # Delete one or many documents by id
  #   solr.delete_by_id 10
  #   solr.delete_by_id([12, 41, 199])
  def delete_by_id(id)
    update message.delete_by_id(id)
  end
  
  # delete one or many documents by query
  #   solr.delete_by_query 'available:0'
  #   solr.delete_by_query ['quantity:0', 'manu:"FQ"']
  def delete_by_query(query)
    update message.delete_by_query(query)
  end
  
  protected
  
  # shortcut to solr::message
  def message
    RSolr::Message
  end
  
  # sets default params etc.. - could be used as a mapping hook
  # type of request should be passed in here? -> map_params(:query, {})
  def map_params(params)
    params||={}
    {:wt=>:ruby}.merge(params)
  end
  
  # "adapter_response" must be a hash with the following keys:
  #   :params - a sub hash of standard solr params
  #   : body - the raw response body from the solr server
  # This method will evaluate the :body value if the params[:wt] == :ruby
  # otherwise, the body is returned
  # The return object has a special method attached called #adapter_response
  # This method gives you access to the original response from the adapter,
  # so you can access things like the actual :url sent to solr,
  # the raw :body, original :params and original :data
  def adapt_response(adapter_response)
    data = adapter_response[:body]
    # if the wt is :ruby, evaluate the ruby string response
    if adapter_response[:params][:wt] == :ruby
      data = Kernel.eval(data)
      # attach a method called #adapter_response that returns the original adapter response value
      def data.adapter_response
        @adapter_response
      end
      data.send(:instance_variable_set, '@adapter_response', adapter_response)
    end
    data
  end
  
end