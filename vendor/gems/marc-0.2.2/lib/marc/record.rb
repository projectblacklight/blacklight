module MARC

  # A class that represents an individual MARC record. Every record
  # is made up of a collection of MARC::DataField objects. 
  #
  # MARC::Record mixes in Enumerable to enable access to constituent
  # DataFields. For example, to return a list of all subject DataFields:
  #
  #   record.find_all {|field| field.tag =~ /^6../}  
  # 
  # The accessor 'fields' is also an Array of MARC::DataField objects which
  # the client can access or modifyi if neccesary.
  #
  #   record.fields.delete(field)
  # 
  # Other accessor attribute: 'leader' for record leader as String
 
  class Record
    include Enumerable

    # the record fields
    attr_accessor :fields

    # the record leader
    attr_accessor :leader

    def initialize
      @fields = []
      # leader is 24 bytes
      @leader = ' ' * 24
      # leader defaults:
      # http://www.loc.gov/marc/bibliographic/ecbdldrd.html
      @leader[10..11] = '22'
      @leader[20..23] = '4500'
    end

    # add a field to the record
    #   record.append(MARC::DataField.new( '100', '2', '0', ['a', 'Fred']))

    def append(field)
      @fields.push(field)
    end

    # alias to append
    
    def <<(field)
      append(field)
    end

    # each() is here to support iterating and searching since MARC::Record
    # mixes in Enumberable
    #
    # iterating through the fields in a record:
    #   record.each { |f| print f }
    #
    # getting the 245
    #   title = record.find {|f| f.tag == '245'}
    #
    # getting all subjects
    #   subjects = record.find_all {|f| ('600'..'699') === f.tag}

    def each
      for field in @fields
        yield field
      end
    end

    # You can lookup fields using this shorthand:
    #   title = record['245']

    def [](tag)
      return self.find {|f| f.tag == tag}
    end

    # Factory method for creating a MARC::Record from MARC21 in 
    # transmission format.
    #
    #   record = MARC::Record.new_from_marc(marc21)
    #
    # in cases where you might be working with somewhat flawed 
    # MARC data you may want to use the :forgiving parameter which
    # will bypass using field byte offsets and simply look for the
    # end of field byte to figure out the end of fields.
    #
    #  record = MARC::Record.new_from_marc(marc21, :forgiving => true)

    def self.new_from_marc(raw, params={})
      return MARC::Reader.decode(raw, params)
    end


    # Returns a record in MARC21 transmission format (ANSI Z39.2). 
    # Really this is just a wrapper around MARC::MARC21::encode
    #
    #   marc = record.to_marc()

    def to_marc 
      return MARC::Writer.encode(self)
    end

    # Handy method for returning the MARCXML serialization for a
    # MARC::Record object. You'll get back a REXML::Document object.
    # Really this is just a wrapper around MARC::XMLWriter::encode
    #
    #   xml_doc = record.to_xml()

    def to_xml
      return MARC::XMLWriter.encode(self, :include_namespace => true)
    end

    # Handy method for returning a hash mapping this records values
    # to the Dublin Core.
    #
    #   dc = record.to_dublin_core()
    #   print dc['title']

    def to_dublin_core
      return MARC::DublinCore.map(self)
    end

    # Returns a string version of the record, suitable for printing

    def to_s
      str = "LEADER #{leader}\n"
      for field in fields:
        str += field.to_s() + "\n"
      end
      return str
    end


    # For testing if two records can be considered equal.

    def ==(other)
      return self.to_s == other.to_s
    end


    # Handy for using a record in a regex:
    #   if record =~ /Gravity's Rainbow/ then print "Slothrop" end

    def =~(regex)
      return self.to_s =~ regex 
    end

  end
end
