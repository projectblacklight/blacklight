require 'kaminari'

class Blacklight::SolrResponse < HashWithIndifferentAccess

  autoload :Spelling, 'blacklight/solr_response/spelling'
  autoload :Facets, 'blacklight/solr_response/facets'
  autoload :MoreLikeThis, 'blacklight/solr_response/more_like_this'

  include Kaminari::PageScopeMethods
  

  module PaginationMethods

    def limit_value #:nodoc:
      rows
    end

    def offset_value #:nodoc:
      start
    end

    def total_count #:nodoc:
      total
    end

    ## Methods in kaminari master that we'd like to use today.
    # Next page number in the collection
    def next_page
      current_page + 1 unless last_page?
    end

    # Previous page number in the collection
    def prev_page
      current_page - 1 unless first_page?
    end
  end

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
