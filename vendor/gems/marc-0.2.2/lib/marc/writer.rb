module MARC

  # A class for writing MARC records as MARC21.

  class Writer

    # the constructor which you must pass a file path
    # or an object that responds to a write message

    def initialize(file)
      if file.class == String
        @fh = File.new(file,"w")
      elsif file.respond_to?('write')
        @fh = file
      else
        throw "must pass in file name or handle"
      end
    end


    # write a record to the file or handle

    def write(record)
      @fh.write(MARC::Writer.encode(record))
    end


    # close underlying filehandle

    def close
      @fh.close
    end


    # a static method that accepts a MARC::Record object
    # and returns the record encoded as MARC21 in transmission format

    def self.encode(record)
      directory = ''
      fields = ''
      offset = 0
      for field in record.fields

        # encode the field
        field_data = ''
        if field.class == MARC::DataField 
          field_data = field.indicator1 + field.indicator2 
          for s in field.subfields
            field_data += SUBFIELD_INDICATOR + s.code + s.value
          end
        elsif field.class == MARC::ControlField
          field_data = field.value
        end
        field_data += END_OF_FIELD

        # calculate directory entry for the field
        field_length = field_data.length()
        directory += sprintf("%03s%04i%05i", field.tag, field_length, 
          offset)

        # add field to data for other fields
        fields += field_data 

        # update offset for next field
        offset += field_length
      end

      # determine the base (leader + directory)
      base = record.leader + directory + END_OF_FIELD

      # determine complete record
      marc = base + fields + END_OF_RECORD

      # update leader with the byte offest to the end of the directory
      marc[12..16] = sprintf("%05i", base.length())

      # update the record length
      marc[0..4] = sprintf("%05i", marc.length())
      
      # store updated leader in the record that was passed in
      record.leader = marc[0..LEADER_LENGTH-1]

      # return encoded marc
      return marc 
    end
  end
end
