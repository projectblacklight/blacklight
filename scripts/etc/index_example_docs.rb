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


require 'rubygems'
require 'solr'

DARK='dark'
MEDIUM='medium'
BRIGHT='bright'

LIQUID='liquid'
GAS='gas'
SOLID='solid'

COLORS={
  :red=>BRIGHT,
  :blue=>DARK,
  :purple=>DARK,
  :orange=>BRIGHT,
  :pink=>MEDIUM,
  :gray=>MEDIUM,
  :black=>DARK,
  :ruby=>DARK,
  :sapphire=>DARK,
  :white=>BRIGHT
}

MATERIALS={
  :plastic=>SOLID,
  :wood=>SOLID,
  :carbon=>GAS,
  :water=>LIQUID,
  :ink=>LIQUID,
  :salt=>SOLID,
  :silicon=>SOLID,
  :lead=>SOLID,
  :milk=>LIQUID
}

def determine_look_and_feel(color, material)
  "#{color.last} and #{material.last}"
end

require 'linguistics'
Linguistics::use(:en)
def create_doc(num)
  color=COLORS.sort_by{rand}.first
  material=MATERIALS.sort_by{rand}.first
  {
    :id=>num,
    :text=>"This is the #{num.en.ordinal} document. It\'s fabulous.",
    :title_text=>"Number #{num.en.numwords}",
    :color_text=>color.first.to_s,
    :material_text=>material.first.to_s,
    :look_and_feel_facet=>determine_look_and_feel(color, material)
  }
end

solr=Solr::Connection.new

50.times do |i|
  puts "indexing doc #{i}"
  solr.add(create_doc(i))
end

response=solr.commit
puts response ? 'Commit successful' : "Commit failed: #{response}"