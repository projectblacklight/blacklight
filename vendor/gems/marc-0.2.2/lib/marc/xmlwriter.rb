require 'rexml/document'
require 'rexml/text'
require 'rexml/formatters/default'

module MARC
  
  # A class for writing MARC records as MARCXML.
  # BIG CAVEAT! XMLWriter will *not* convert your MARC8 to UTF8
  # bug the authors to do this if you need it
  
  class XMLWriter
    
    # the constructor which you must pass a file path
    # or an object that responds to a write message
    # the second argument is a hash of options, currently
    # only supporting one option, stylesheet
    # 
    # writer = XMLWriter.new 'marc.xml', :stylesheet => 'style.xsl'
    # writer.write record
    
    def initialize(file, opts={})
      @writer = REXML::Formatters::Default.new
      if file.class == String
        @fh = File.new(file,"w")
      elsif file.respond_to?('write')
        @fh = file
      else
        throw "must pass in file name or handle"
      end
      
      @fh.write("<?xml version='1.0'?>\n")
      if opts[:stylesheet]
        @fh.write(
          %Q{<?xml-stylesheet type="text/xsl" href="#{opts[:stylesheet]}"?>\n})
      end
      @fh.write("<collection xmlns='" + MARC_NS + "' " +
        "xmlns:xsi='http://www.w3.org/2001/XMLSchema-instance' " +
        "xsi:schemaLocation='" + MARC_NS + " " + MARC_XSD + "'>")
      @fh.write("\n")
    end
    
    
    # write a record to the file or handle
    
    def write(record)
      @writer.write(MARC::XMLWriter.encode(record), @fh)
      @fh.write("\n")
    end
    
    
    # close underlying filehandle
    
    def close
      @fh.write("</collection>")
      @fh.close
    end

    
    # a static method that accepts a MARC::Record object
    # and returns a REXML::Document for the XML serialization.

    def self.encode(record, opts={})
      singleChar = Regexp.new('[\da-z ]{1}')
      ctrlFieldTag = Regexp.new('00[1-9A-Za-z]{1}')
      
      # Right now, this writer handles input from the strict and
      # lenient MARC readers. Because it can get 'loose' MARC in, it
      # attempts to do some cleanup on data values that are not valid
      # MARCXML.
      
      # TODO? Perhaps the 'loose MARC' checks should be split out
      # into a tolerant MARCXMLWriter allowing the main one to skip
      # this extra work.
      
      # TODO: At the very least there should be some logging
      # to record our attempts to account for less than perfect MARC.
      
      e = REXML::Element.new('record')
      e.add_namespace(MARC_NS) if opts[:include_namespace]

      # MARCXML only allows alphanumerics or spaces in the leader
      record.leader.gsub!(/[^\w|^\s]/, 'Z')
      
      # MARCXML is particular about last four characters; ILSes aren't
      if (record.leader[20..23] != "4500")
        record.leader[20..23] = "4500"
      end

      # MARCXML doesn't like a space here so we need a filler character: Z
      if (record.leader[6..6] == " ")
        record.leader[6..6] = "Z"
      end
      
      leader = REXML::Element.new("leader")
      leader.add_text(record.leader)
      e.add_element(leader)
      
      for field in record.fields
        if field.class == MARC::DataField 
          datafield_elem = REXML::Element.new("datafield")
          
          # If marc is leniently parsed, we may have some dirty data; using
          # the 'z' ind1 value should help us locate these later to fix
          if (field.indicator1.match(singleChar) == nil)
            field.indicator1 = 'z'
          end
          
          # If marc is leniently parsed, we may have some dirty data; using
          # the 'z' ind2 value should help us locate these later to fix
          if (field.indicator2.match(singleChar) == nil)
            field.indicator2 = 'z'
          end
          
          datafield_elem.add_attributes({
            "tag"=>field.tag,
            "ind1"=>field.indicator1,
            "ind2"=>field.indicator2
          })

          for subfield in field.subfields
            subfield_element = REXML::Element.new("subfield")
            
            # If marc is leniently parsed, we may have some dirty data; using
            # the blank subfield code should help us locate these later to fix
            if (subfield.code.match(singleChar) == nil)
              subfield.code = ' '
            end
            
            subfield_element.add_attribute("code", subfield.code)
            text = subfield.value
            subfield_element.add_text(text)
            datafield_elem.add_element(subfield_element)
          end
          
          e.add_element datafield_elem
        elsif field.class == MARC::ControlField
          control_element = REXML::Element.new("controlfield")
          
          # We need a marker for invalid tag values (we use 000)
          unless field.tag.match(ctrlFieldTag)
            field.tag = "00z"
          end
          
          control_element.add_attribute("tag", field.tag)
          text = field.value
          control_element.add_text(text)
          e.add_element(control_element)
        end
      end
      
      # return xml
      return e 
    end
  end
end
