
## This module and the ::Document class in it is DEPRECATED, and will go away.
# It has been replaced by
# code using the new document extension framework. See
# Blacklight::Solr::Document::Marc and Blacklight::Solr::Document::MarcExport
# This code should not really be changed, or used anymore. It is frozen
# and deprecated until removed. 
module Blacklight::Marc
  
  autoload :Citation, 'blacklight/marc/citation.rb'
  
  class UnsupportedMarcFormatType < RuntimeError; end
  
  class Document
    
    attr_reader :marc
    
    include Citation
    
    def initialize(marc_data, marc_type)
      case marc_type.to_s
        when 'marcxml'
          reader = MARC::XMLReader.new(StringIO.new(marc_data)).to_a
          @marc = reader[0]
        when 'marc21'
          reader = MARC::Record.new_from_marc(marc_data)
          @marc = reader
        else
          raise UnsupportedMarcFormatType.new("Only marcxml and marc21 are supported.")
      end
    end
    
    def marc_xml
      @marc.to_xml.to_s
    end

    def to_xml
      if @marc 
        self.marc_xml
      else
        "<not-implemented/>"
      end
    end
  end
  
end
