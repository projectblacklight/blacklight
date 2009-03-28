require 'ostruct'
require 'rubygems'
require 'marc'

class SolrDocument < OpenStruct
  
  attr_reader :table  
  
  def initialize(h)  
    super(h)
    if self.marc_display
      reader = MARC::XMLReader.new(StringIO.new(self.marc_display)).to_a
      self.marc = reader[0]
    end
    self.solr_id = h['id']
  end
  
  def [](key)
    self.__send__(key)
  end
  
  def marc_xml
    return nil if self.marc.blank?
    self.marc.to_xml.to_s
  end
  
  def to_xml
    if self.marc 
      self.marc_xml
    else
      "<not-implemented/>"
    end
  end
  
end

