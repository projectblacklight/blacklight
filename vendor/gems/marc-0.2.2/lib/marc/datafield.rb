require 'marc/subfield'
require 'marc/record'

module MARC

  # MARC records contain data fields, each of which has a tag, 
  # indicators and subfields. Tags for data fields must be in
  # the range 010-999.
  # Accessor attributes: tag, indicator1, indicator2
  # 
  # DataField mixes in Enumerable to enable access to it's constituent
  # Subfield objects. For instance, if you have a DataField representing
  # a 856 tag, and want to find all 'z' subfields:
  #
  #   subfield_z = field.find_all {|subfield| subfield.code == 'z'}
  #
  # Also, the accessor 'subfields' is an array of MARC::Subfield objects
  # which can be accessed or modified by the client directly if
  # neccesary. 

  class DataField
    include Enumerable

    # The tag for the field
    attr_accessor :tag

    # The first indicator
    attr_accessor :indicator1

    # The second indicator
    attr_accessor :indicator2

    # A list of MARC::Subfield objects
    attr_accessor :subfields


    # Create a new field with tag, indicators and subfields.
    # Subfields are passed in as comma separated list of 
    # MARC::Subfield objects, 
    # 
    #   field = MARC::DataField.new('245','0','0',
    #     MARC::Subfield.new('a', 'Consilience :'),
    #     MARC::Subfield.new('b', 'the unity of knowledge ',
    #     MARC::Subfield.new('c', 'by Edward O. Wilson.'))
    # 
    # or using a shorthand:
    # 
    #   field = MARC::DataField.new('245','0','0',
    #     ['a', 'Consilience :'],['b','the unity of knowledge ',
    #     ['c', 'by Edward O. Wilson.'] )

    def initialize(tag, i1=' ', i2=' ', *subfields)
      # if the tag is less than 3 characters long and 
      # the string is all numeric then we pad with zeros
      if tag.length < 3 and /^[0-9]*$/ =~ tag
        @tag = "%03d" % tag
      else
        @tag = tag 
      end
      # can't allow nil to be passed in or else it'll 
      # screw us up later when we try to encode
      @indicator1 = i1 == nil ? ' ' : i1
      @indicator2 = i2 == nil ? ' ' : i2
      @subfields = []

      # must use MARC::ControlField for tags < 010
      if @tag.to_i < 10 and not @tag =~ /[A-z]/
        raise MARC::Exception.new(),
          "MARC::DataField objects can't have tags < 010"
      end

      # allows MARC::Subfield objects to be passed directly
      # or a shorthand of ['a','Foo'], ['b','Bar']
      subfields.each do |subfield| 
        case subfield
        when MARC::Subfield
          @subfields.push(subfield)
        when Array
          if subfield.length > 2
            raise MARC::Exception.new(),
              "arrays must only have 2 elements" 
          end
          @subfields.push(
            MARC::Subfield.new(subfield[0],subfield[1]))
        else 
          raise MARC::Exception.new(), 
            "invalid subfield type #{subfield.class}"
        end
      end
    end


    # Returns a string representation of the field such as:
    #  245 00 $aConsilience :$bthe unity of knowledge $cby Edward O. Wilson.

    def to_s
      str = "#{tag} "
      str += "#{indicator1}#{indicator2} " 
      @subfields.each { |subfield| str += subfield.to_s }
      return str
    end


    # Add a subfield (MARC::Subfield) to the field
    #    field.append(MARC::Subfield.new('a','Dave Thomas'))

    def append(subfield)
      @subfields.push(subfield)
    end


    # You can iterate through the subfields in a Field:
    #   field.each {|s| print s}

    def each
      for subfield in subfields
        yield subfield
      end
    end


    # You can lookup subfields with this shorthand. Note it 
    # will return a string and not a MARC::Subfield object.
    #   subfield = field['a']
    
    def [](code)
      subfield = self.find {|s| s.code == code}
      return subfield.value if subfield
      return
    end


    # Two fields are equal if their tag, indicators and 
    # subfields are all equal.

    def ==(other)
      if @tag != other.tag
        return false 
      elsif @indicator1 != other.indicator1
        return false 
      elsif @indicator2 != other.indicator2
        return false 
      elsif @subfields != other.subfields
        return false
      end
      return true
    end


    # To support regex matching with fields
    #
    #   if field =~ /Huckleberry/ ...

    def =~(regex)
      return self.to_s =~ regex
    end


    # to get the field as a string, without the tag and indicators
    # useful in situations where you want a legible version of the field
    #
    # print record['245'].value

    def value
      return(@subfields.map {|s| s.value} .join '')
    end

  end
end
