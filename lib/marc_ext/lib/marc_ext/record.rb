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

module MARCEXT::Record
  
  require 'marc_ext/record/field_045'
  require 'marc_ext/record/format_type'
  
  #
  # Returns an array of strings
  # from field values of a MARC::Record record instance
  # where the marc record field matches the field argument
  # If the field arg is < 010,
  # return the value of that field's combined sub-fields
  #
  def extract(field)
    record = self
    extracted_data = []
    # The tag is the first 3 numbers
    tag = field.to_s[0,3]
    # MARC::DataField's that match
    extracted_fields = record.find_all {|f| f.tag === tag}

    # Used if not a control field (field > 010)
    subfield = (field.to_s.length > 3) ? field.to_s[3].chr : ''

    extracted_fields.each do |field_instance|
      if tag < '010' # get control fields (less than 010)
        # This gets all sub field values (concatenated) and removes a possible ending .
        extracted_data << field_instance.value.sub(/\.$/,'')# rescue nil
      else # data field - expects [0-9]{3}[a-z]{1} - example 100a
        # Loop through sub-fields
        # If the subfield matches, grab it
        field_instance.find_all {|x| x.code === subfield }.each do |sf|
          # remove the ending . and store the value
          extracted_data << sf.value.sub(/\.$/,'')# rescue nil
        end
      end
    end
    # remove nil values, remove duplicates and return
    extracted_data.compact.uniq
  end
  
  ## This should be self.leader[6,1]
  ## There was some confusion about whether this should be [7,1] or [6,1]
  ## I'm now reasonably sure it's [6,1]
  def format_code
    self.leader[6,1].to_s
  end
  
  include Field045
  
  include FormatType
  
end