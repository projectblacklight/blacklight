require 'marc'

module Blacklight::Marc
  
  autoload :Citation, 'blacklight/marc/citation.rb'
  
  class UnsupportedMarcFormatType < RuntimeError; end
  
  class Document
    
    attr_reader :marc
    
    include Citation
    
    def initialize(marc_data, marc_type)
      @marc_data = marc_data
      @marc_type = marc_type
    end

    def to_marc
      @marc ||= load_marc  
    end
    # legacy way of calling:
    alias_method :marc, :to_marc
    
    def marc_xml
      marc.to_xml.to_s
    end

    def load_marc
      case @marc_type.to_s
        when 'marcxml'
          records = MARC::XMLReader.new(StringIO.new(@marc_data)).to_a
          return records[0]
        when 'marc21'
          return MARC::Record.new_from_marc(@marc_data)          
        else
          raise UnsupportedMarcFormatType.new("Only marcxml and marc21 are supported.")
        end
      end
    end
  
end