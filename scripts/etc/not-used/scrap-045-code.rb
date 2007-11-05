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


tmp=[]
tmp += extract_record_data(r, :'650d')
tmp += extract_record_data(r, :'650y')
tmp += extract_record_data(r, :'651y')
tmp += extract_record_data(r, :'655y')

tmp.flatten!

found_range=false

tmp.each do |date|
  found_range=false
  if date =~ /century/i
    puts '****** FOUND CENTURY'
    puts date
    eras << date.sub(/century/, 'Century')
    next
  end
  if date =~ /\d{4}\-\d{4}/
    puts "********************************* FOUND RANGE"
    puts date
    puts eras.inspect
    _start, _end = date.scan(/(\d{4})-(\d{4})/).flatten
    (_start.._end).each do |y|
      puts "#{y} == #{year_to_century(y)}"
      eras << year_to_century(y)
    end
    eras.uniq!
    puts date
    puts eras.inspect
    found_range=true
    #date.scan(/\d{4}-\d{4}/).flatten.each do |year|
    #  eras << year_to_century(year)
    #end
    next
  end
=begin
  if date =~ /\d{4}/
    date.scan(/\d{4}/).flatten.each do |year|
      eras << year_to_century(year)
    end
    next
  end
  if date =~ /b\.?c\.?/i
    date.scan(/\d{1,4}/).flatten.each do |year|
      eras << year_to_century(year) + ' B.C'
    end
    next
  end
  date.scan(/\d{1,4}/).flatten.each do |year|
    puts '************************************************* FOUND EXCEPTIONAL DATE'
    puts "------------------------------------------------- #{year}"
    eras << year_to_century(year)
  end
=end
end
puts "************************* #{eras.compact.uniq}"

sleep 5 if found_range