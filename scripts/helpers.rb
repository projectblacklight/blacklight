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
# mwm4n@virginia.edu 11-08-07
#
# Returns keys from "labels" if an "input" value matches a label's value
# labels can have either an array of values or a single value
# "input" values can be an array or string
# values = ['h']
# labels = {'HOME' => ['h', 'index', 'home']}
# ['HOME'] == values_to_labels(values, labels)
# if "return_input_if_not_found" is true,
#    the input values are returned
#    if no matches are found in the labels
# if "invert_label_hash" is true,
#    The values are used for the keys etc.
#
# NOTE: This could be cleaned up a bit! :)
#
def values_to_labels(input, labels, return_input_if_not_found=true, invert_label_hash=false)
  if invert_label_hash
    l={}
    labels.each_pair do |k,v|
      l[v]=k
    end
    labels=l
  end
  # force type to array, remove nil values
  input = input.to_a.compact
  # collect the labels which have a value that matches the value of in the record_location_codes
  match = labels.select do |label,label_value|
    # Mutiple items?
    found = input.select do |input_value|
      # Does the label have multiple values?
      if label_value.respond_to? :include?
        label_value.include? input_value
      else
        # Just a single valued/string label
        label_value == input_value
      end
    end
    # return true to put this item into the "match" array
    ! found.empty?
  end
  matched_labels = match.collect {|i| i.first}
  if matched_labels.empty?
    return_input_if_not_found ? input : nil
  else
    matched_labels
  end
end