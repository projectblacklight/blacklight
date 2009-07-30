require 'rexml/document'
require 'rexml/parsers/pullparser'

module MARC
  
  class XMLReader
    include Enumerable

    # the constructor which you can pass either a filename:
    #
    #   reader = MARC::XMLReader.new('/Users/edsu/marc.xml')
    #
    # or a File object, 
    #
    #   reader = Marc::XMLReader.new(File.new('/Users/edsu/marc.xml'))
    #
    # or really any object that responds to read(n)
    # 
    #   reader = MARC::XMLReader.new(StringIO.new(xml))
 
    def initialize(file)
      if file.class == String:
        handle = File.new(file)
      elsif file.respond_to?("read", 5)
        handle = file
      else
        throw "must pass in path or File"
      end

      @parser = REXML::Parsers::PullParser.new(handle)
    end

    def each
      while @parser.has_next?
        event = @parser.pull
        # if it's the start of a record element 
        if event.start_element? and strip_ns(event[0]) == 'record'
          yield build_record
        end
      end
    end

    private

    def strip_ns(str)
      return str.sub(/^.*:/, '')
    end

    # will accept parse events until a record has been built up
    #
    def build_record
      record = MARC::Record.new
      data_field = nil
      control_field = nil
      subfield = nil
      text = '' 
      attrs = nil

      while @parser.has_next?
        event = @parser.pull

        if event.text?
          text += REXML::Text::unnormalize(event[0])
          next
        end

        if event.start_element?
          text = ''
          attrs = event[1]
          case strip_ns(event[0])
          when 'controlfield'
            text = ''
            control_field = MARC::ControlField.new(attrs['tag'])
          when 'datafield'
            text = ''
            data_field = MARC::DataField.new(attrs['tag'], attrs['ind1'], 
              attrs['ind2'])
          when 'subfield'
            text = ''
            subfield = MARC::Subfield.new(attrs['code'])
          end
        end

        if event.end_element?
          case strip_ns(event[0])
          when 'leader'
            record.leader = text
          when 'record'
            return record
          when 'controlfield'
            control_field.value = text
            record.append(control_field)
          when 'datafield'
            record.append(data_field)
          when 'subfield'
            subfield.value = text
            data_field.append(subfield)
          end
        end
      end
    end
  end
end
