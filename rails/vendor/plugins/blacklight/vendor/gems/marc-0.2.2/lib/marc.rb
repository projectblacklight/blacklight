#marc is a ruby library for reading and writing MAchine Readable Cataloging
#(MARC). More information about MARC can be found at <http://www.loc.gov/marc>.
#
#USAGE 
#
#    require 'marc'
#
#    # reading records from a batch file
#    reader = MARC::Reader.new('marc.dat')
#    for record in reader
#      puts record['245']['a']
#    end
#
#    # creating a record 
#    record = MARC::Record.new()
#    record.add_field(MARC::DataField.new('100', '0',  ' ', ['a', 'John Doe']))
#
#    # writing a record
#    writer = MARC::Writer.new('marc.dat')
#    writer.write(record)
#    writer.close()
#
#    # writing a record as XML
#    writer = MARC::XMLWriter.new('marc.xml')
#    writer.write(record)
#    writer.close()

require 'marc/constants'
require 'marc/record'
require 'marc/datafield'
require 'marc/controlfield'
require 'marc/subfield'
require 'marc/reader'
require 'marc/writer'
require 'marc/exception'
require 'marc/xmlwriter'
require 'marc/xmlreader'
require 'marc/dublincore'
