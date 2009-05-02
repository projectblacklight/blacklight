require 'marc'
module BlacklightMarc
  attr_reader :table, :marc
  class Document
    include MarcCitation
    def initialize(h)
      marc_field = Blacklight.config[:raw_storage_field]
      marc_type = Blacklight.config[:raw_storage_type]
      if h.has_key? marc_field
        marc_data = h.fetch marc_field
        case marc_type
          when 'marcxml'
            reader = MARC::XMLReader.new(StringIO.new(marc_data)).to_a
            @marc = reader[0]
          when 'marc21'
            reader = MARC::Record.new_from_marc(marc_data)
            @marc = reader
          else
          # Some Default Object created from data?
        end
      end
    end
    
    def marc
      @marc
    end
    def marc_xml
      return nil if @marc.blank?
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