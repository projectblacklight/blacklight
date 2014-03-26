class Blacklight::SolrResponse < HashWithIndifferentAccess

  require  'blacklight/solr_response/pagination_methods'

  autoload :Spelling, 'blacklight/solr_response/spelling'
  autoload :Facets, 'blacklight/solr_response/facets'
  autoload :MoreLikeThis, 'blacklight/solr_response/more_like_this'
  autoload :GroupResponse, 'blacklight/solr_response/group_response'
  autoload :Group, 'blacklight/solr_response/group'

  include PaginationMethods

  attr_reader :request_params
  def initialize(data, request_params)
    super(data)
    @request_params = request_params
    extend Spelling
    extend Facets
    extend Response
    extend MoreLikeThis
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
      response['docs'] || []
    end
  end
  
  def documents
    docs.collect{|doc| SolrDocument.new(doc, self) }
  end

  def spelling
    self['spelling']
  end

  def grouped
    @groups ||= self["grouped"].map do |field, group|
      # grouped responses can either be grouped by:
      #   - field, where this key is the field name, and there will be a list
      #        of documents grouped by field value, or:
      #   - function, where the key is the function, and the documents will be
      #        further grouped by function value, or:
      #   - query, where the key is the query, and the matching documents will be
      #        in the doclist on THIS object
      if group["groups"] # field or function
        GroupResponse.new field, group, self
      else # query
        Group.new field, group, self
      end
    end
  end

  def group key
    grouped.select { |x| x.key == key }.first
  end

  def grouped?
    self.has_key? "grouped"
  end

  module Response
    def response
      self[:response] || {}
    end
    
    # short cut to response['numFound']
    def total
      response[:numFound].to_s.to_i
    end
    
    def start
      response[:start].to_s.to_i
    end

    def empty?
      total == 0
    end
    
  end
end
