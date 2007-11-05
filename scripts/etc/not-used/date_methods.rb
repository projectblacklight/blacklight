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



O45_A_TIME_PERIODS_BC={
  :a0=>"before 2999",
  :b0=>"2999-2900",
  :b1=>"2899-2800",
  :b2=>"2799-2700",
  :b3=>"2699-2600",
  :b4=>"2599-2500",
  :b5=>"2499-2400",
  :b6=>"2399-2300",
  :b7=>"2299-2200",
  :b8=>"2199-2100",
  :b9=>"2099-2000",
  :c0=>"1999-1900",
  :c1=>"1899-1800",
  :c2=>"1799-1700",
  :c3=>"1699-1600",
  :c4=>"1599-1500",
  :c5=>"1499-1400",
  :c6=>"1399-1300",
  :c7=>"1299-1200",
  :c8=>"1199-1100",
  :c9=>"1099-1000",
  :d0=>"999-900",
  :d1=>"899-800",
  :d2=>"799-700",
  :d3=>"699-600",
  :d4=>"599-500",
  :d5=>"499-400",
  :d6=>"399-300",
  :d7=>"299-200",
  :d8=>"199-100",
  :d9=>"99-1"
}

O45_A_TIME_PERIODS_CE={
  :e=>"1-99",
  :f=>"100-199",
  :g=>"200-299",
  :h=>"300-399",
  :i=>"400-499",
  :j=>"500-599",
  :k=>"600-699",
  :l=>"700-799",
  :m=>"800-899",
  :n=>"900-999",
  :o=>"1000-1099",
  :p=>"1100-1199",
  :q=>"1200-1299",
  :r=>"1300-1399",
  :s=>"1400-1499",
  :t=>"1500-1599",
  :u=>"1600-1699",
  :v=>"1700-1799",
  :w=>"1800-1899",
  :x=>"1900-1999",
  :y=>"2000-2099"
}

O45_A_TIME_PERIODS = O45_A_TIME_PERIODS_BC.merge O45_A_TIME_PERIODS_CE
O45_A_TIME_PERIOD_CE_MATCH=/^[e-y]/
O45_A_TIME_PERIOD_BC_MATCH=/^[a-d][0-9]/

require 'linguistics'
Linguistics::use(:en)
def year_to_century(year)
  (year.scan(/^\d{2}/).first.to_i+1).en.ordinal + ' Century'
end

def yyyymmddhh(value)
  value.scan(/(\d{4})(\d{2})?(\d{2})?/).collect {|i| i.to_s }
end

def o45_b_label(value)
  ce=%r(^d)
  if value =~ ce
    no_code=value.sub(ce, '')
    dates=yyyymmddhh(no_code)
    return year_to_century(dates.first)
  end
  bc=%r(^c)
  # Month for B.C. dates?
  return value.sub(bc, '') + " B.C." if value =~ bc
end

def determine_era(record)
  o45=record['045']
  # special codes:
  a_subs=o45.find_all {|r| r.code =='a'}
  # bc or ce
  b_subs=o45.find_all {|r| r.code =='b'}
  # years bc if all numeric; $c 225000000 $c 500000000
  c_subs=o45.find_all {|r| r.code =='c'}
  
  unless a_subs.empty?
    a_subs.each do |a|
      values=a.value.scan(/(.{2})(.{2})/)
      if a.value =~ O45_A_TIME_PERIOD_CE_MATCH
        puts 'CE TIME PERIOD'
        map=O45_A_TIME_PERIODS_CE
        if nil#values.any? {|i| i.index('-') }
          puts "GENERAL :: #{a.value}"
          puts "#{map[values[0][0].to_s]} - #{map[values[1][0].to_s]}"
        else
          puts "SPECIFIC :: #{a.value}"
          
          one = values.first[0][0,1]
          decade_one = values.first[0][1,1].to_i * 10
          range_one = map[one.to_sym]
          
          two = values.first[1][0,1]
          decade_two = values.first[1][1,1].to_i * 10
          range_two = map[two.to_sym]
          
          #puts "#{one} #{range_one} --- #{two} #{range_two}"
          
          if decade_one > 0
            puts '1 HAS DECADE'
            _start = range_one.split('-').first.to_i + decade_one
          else
            _start = range_one.split('-').first.to_i
          end
          
          if decade_two > 0
            puts '2 HAS DECADE'
            _end = range_two.split('-').first.to_i + decade_two
          else
            _end = range_two.split('-').last.to_i
          end
          
          puts "#{_start} - #{_end}"
          
        end
      elsif a.value =~ O45_A_TIME_PERIOD_BC_MATCH
        puts 'BC TIME PERIOD'
        map = O45_A_TIME_PERIODS_BC
      else
        puts 'Invalid Match for o45 $a'
      end
    end
  end
  ''
  #unless b_subs.empty?
  #  b_subs.collect {|b| o45_b_label(b.value) }
  #end
end