##########################################################################
# Copyright 2008 Rector and Visitors of the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################


#
# "data source" - filters out unwanted records and sometimes filters fields
#
class ML::DataSource
  
  SKIPPED_LOCATIONS = ['UL-PRESERV','UNKNOWN','LOST','LOST-NRO','DISCARD','WITHDRAWN','UL-PRNTSVS','BARRED','BURSARED','LOST-PAID',
    'LOSTCLOSED','ORD-CLOSED','SE-TS-OFF','LOST-ASSUM','LOST-CLAIM','LAW-FACOFF','LAW-PAID','HS-BD96-97',
    'HS-BD97-98','HS-BD98-99','HS-BD99-00','HS-BD2001','HS-BD2002','HS-BD2003','HS-BD2004','HS-BD2005','HS-CLENP00','EQUIPMENT',
    'HS-WD96/97','HS-WD98/99','HS-WD99/00','HS-WD2001','HS-WD2002','HS-WD2003','HS-WD2004','HS-WD2005','HS-WED9798','HS-WED2001',
    'HS-WED2002','HS-WTHDRAW','UL-NOTHELD','UL-CATDEPT','UL-ACQDEPT','UL-ILSDEPT','UL-SYSDEPT','UL-ADMIN','UL-SS-DEPT','UL-HUMDEPT',
    'UL-RISDEPT','UL-SC-DEPT','UL-FA-DEPT','UL-CL-DEPT','UL-ED-DEPT','UL-SE-DEPT','UL-SUPPORT','RSRVSHADOW','CL-STORAGE','ORD-CANCLD',
    'HS-WD97/98','HS-COVLOC']
  
  def initialize(marc_filename)
    @reader = MARC::ForgivingReader.new(marc_filename)
  end

  def each
    total=0
    @reader.each do |record|
      #if total >= 1000
      #  return
      #end
      if in_valid_location?(record)
        total += 1
        # if in bad location (LOST), skip
        filter_999_o_value(record)
        yield record
      else
        puts "SKIPPED MARC RECORD: #{record['001']}"
      end
    end
  end
  
  protected
  
  # Only process records that have at least one
  # location not in the SKIPPED_LOCATIONS list
  # TODO: clear the skipped locations so they do not become facets
  def in_valid_location?(record)
    locations = record.extract('999k') + record.extract('999l')
    remaining_locations = locations - SKIPPED_LOCATIONS
    locations.size > 0
  end
  
  # Wipe 999 $o values
  # In some cases, this may contain data that
  # SHOULD NOT be public for **security** reasons
  def filter_999_o_value(record)
    nine_nine_nines = record.find_all {|f| f.tag === '999'}
    nine_nine_nines.each do |field|
      subfield_os = field.find_all {|subfield| subfield.code == 'o'}
      subfield_os.each {|sf| sf.value = 'OCLEANED' }
    end
  end
  
end