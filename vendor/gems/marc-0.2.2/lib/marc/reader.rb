module MARC

  class Reader
    include Enumerable

    # The constructor which you may pass either a path 
    #
    #   reader = MARC::Reader.new('marc.dat')
    # 
    # or, if it's more convenient a File object:
    #
    #   fh = File.new('marc.dat')
    #   reader = MARC::Reader.new(fh)
    #
    # or really any object that responds to read(n)
    #
    #   # marc is a string with a bunch of records in it
    #   reader = MARC::Reader.new(StringIO.new(reader))
    
    def initialize(file)
      if file.class == String:
        @handle = File.new(file)
      elsif file.respond_to?("read", 5)
        @handle = file
      else
        throw "must pass in path or file"
      end
    end

    # to support iteration:
    #   for record in reader
    #     print record
    #   end
    #
    # and even searching:
    #   record.find { |f| f['245'] =~ /Huckleberry/ }

    def each 
      # while there is data left in the file
      while rec_length_s = @handle.read(5)
        # make sure the record length looks like an integer
        rec_length_i = rec_length_s.to_i
        if rec_length_i == 0:
          raise MARC::Exception.new("invalid record length: #{rec_length_s}")
        end

        # get the raw MARC21 for a record back from the file
        # using the record length
        raw = rec_length_s + @handle.read(rec_length_i-5)
        

        # create a record from the data and return it
        #record = MARC::Record.new_from_marc(raw)
        record = MARC::Reader.decode(raw)
        yield record 
      end
    end


    # A static method for turning raw MARC data in transission
    # format into a MARC::Record object.

    def self.decode(marc, params={})
      record = Record.new()
      record.leader = marc[0..LEADER_LENGTH-1]

      # where the field data starts
      base_address = record.leader[12..16].to_i

      # get the byte offsets from the record directory
      directory = marc[LEADER_LENGTH..base_address-1]

      throw "invalid directory in record" if directory == nil

      # the number of fields in the record corresponds to 
      # how many directory entries there are
      num_fields = directory.length / DIRECTORY_ENTRY_LENGTH

      # when operating in forgiving mode we just split on end of
      # field instead of using calculated byte offsets from the 
      # directory
      all_fields = marc[base_address..-1].split(END_OF_FIELD)

      0.upto(num_fields-1) do |field_num|

        # pull the directory entry for a field out
        entry_start = field_num * DIRECTORY_ENTRY_LENGTH
        entry_end = entry_start + DIRECTORY_ENTRY_LENGTH
        entry = directory[entry_start..entry_end]
        
        # extract the tag
        tag = entry[0..2]

        # get the actual field data
        # if we were told to be forgiving we just use the
        # next available chuck of field data that we 
        # split apart based on the END_OF_FIELD
        field_data = ''
        if params[:forgiving]
          field_data = all_fields.shift()

        # otherwise we actually use the byte offsets in 
        # directory to figure out what field data to extract
        else
          length = entry[3..6].to_i
          offset = entry[7..11].to_i
          field_start = base_address + offset
          field_end = field_start + length - 1
          field_data = marc[field_start..field_end]
        end

        # remove end of field
        field_data.delete!(END_OF_FIELD)
         
        # add a control field or data field
        if tag < '010'
          record.append(MARC::ControlField.new(tag,field_data))
        else
          field = MARC::DataField.new(tag)

          # get all subfields
          subfields = field_data.split(SUBFIELD_INDICATOR)

          # must have at least 2 elements (indicators, and 1 subfield)
          # TODO some sort of logging?
          next if subfields.length() < 2

          # get indicators
          indicators = subfields.shift()
          field.indicator1 = indicators[0,1]
          field.indicator2 = indicators[1,1]

          # add each subfield to the field
          subfields.each() do |data|
            subfield = MARC::Subfield.new(data[0,1],data[1..-1])
            field.append(subfield)
          end

          # add the field to the record
          record.append(field)
        end
      end

      return record
    end
  end


  # Like Reader ForgivingReader lets you read in a batch of MARC21 records
  # but it does not use record lengths and field byte offets found in the 
  # leader and directory. It is not unusual to run across MARC records
  # which have had their offsets calcualted wrong. In situations like this
  # the vanilla Reader may fail, and you can try to use ForgivingReader.
  
  # The one downside to this is that ForgivingReader will assume that the
  # order of the fields in the directory is the same as the order of fields
  # in the field data. Hopefully this will be the case, but it is not 
  # 100% guranteed which is why the normal behavior of Reader is encouraged.

  class ForgivingReader
    include Enumerable

    def initialize(file)
      if file.class == String
        @handle = File.new(file)
      elsif file.respond_to?("read", 5)
        @handle = file
      else
        throw "must pass in path or File object"        
      end
    end


    def each 
      @handle.each_line(END_OF_RECORD) do |raw| 
        begin
          record = MARC::Reader.decode(raw, :forgiving => true)
          yield record 
        rescue StandardError => e
          # caught exception just keep barrelling along
          # TODO add logging
        end
      end
    end
  end
end
