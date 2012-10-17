class Blacklight::SolrResponse < Mash

  autoload :Spelling, 'blacklight/solr_response/spelling'
  autoload :Facets, 'blacklight/solr_response/facets'

  attr_reader :request_params
  def initialize(data, request_params)
    super(data)
    @request_params = request_params
    extend Spelling
    extend Facets
    extend Response
  end

  def header
    self['responseHeader']
  end
  

  def update(other_hash) 
    other_hash.each_pair { |key, value| self[key] = value } 
    self 
  end 

  def params
      (header and header['params']) ? header['params'] : request_params
  end

  def rows
      params[:rows].to_i
  end

  def docs
    @docs ||= begin
      response['docs']
    end
  end

  def spelling
    self['spelling']
  end

  module Response
    def response
      self[:response]
    end
    
    # short cut to response['numFound']
    def total
      response[:numFound].to_s.to_i
    end
    
    def start
      response[:start].to_s.to_i
    end
    
  end
end
