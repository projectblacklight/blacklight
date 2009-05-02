require 'ostruct'
require 'rubygems'

class SolrDocument < OpenStruct
  attr_reader :table  
  def initialize(h)  
    super(h)
    storage_type = Blacklight.config[:raw_storage_type]
    case storage_type
      when 'marcxml', 'marc21'
        self.storage = BlacklightMarc::Document.new(h) unless !h.has_key? Blacklight.config[:raw_storage_field]
      else
      # Some Default Object created from data?
    end
    self.solr_id = h['id']
  end
  
  def [](key)
    self.__send__(key)
  end
  
end