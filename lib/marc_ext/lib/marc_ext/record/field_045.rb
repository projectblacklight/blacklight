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

require 'linguistics'
Linguistics::use(:en)

#
# See http://www.oclc.org/bibformats/en/0xx/045.shtm
#

module MARCEXT::Record::Field045
  
  TIME_PERIODS_BC={
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

  TIME_PERIODS_CE={
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

  O45_A_TIME_PERIODS = TIME_PERIODS_BC.merge TIME_PERIODS_CE
  TIME_PERIOD_CE_MATCH=/^[e-y]/
  TIME_PERIOD_BC_MATCH=/^[a-d][0-9]/
  
  def unique_045_eras
    eras=[]
    unless self['045'].nil?
      o45 = self['045']
      a=o45.find_all {|sub| sub.code =='a'}
      b=o45.find_all {|sub| sub.code =='b'}
      eras << b.collect do |bval|
        (DateHelpers.o45_b_label(bval.value.strip)).to_s
      end
      #puts eras
      eras << a.collect do |aval|
        (DateHelpers.o45_a_label(aval.value.strip)).to_s
      end
    end
    ## you have to flatten the eras array, otherwise the uniq command won't work. 
    
    ## added compact to chuck nil values! mwm4n@virginia.edu - 11-08-07
    eras = eras.flatten.compact.uniq
    # remove empty strings:
    eras.reject {|v| v.to_s.empty? }
  end
  
  module DateHelpers
    
    #
    # Converts a numeric year to it's century
    # DateHelpers.year_to_century(1986) == '20th Century'
    #
    def self.year_to_century(year)
      century = ((year.to_i/100)+1)
      century.en.ordinal + ' Century'
    end
    
    #
    # Converts a yyyymmdd date into an array
    #
    def self.yyyymmddhh(b)
      b.scan(/(\d{4})(\d{2})?(\d{2})?/).flatten
    end
    
    #
    #
    #
    def self.o45_a_label(a)
      match = nil
      if a =~ TIME_PERIOD_CE_MATCH
        match = TIME_PERIODS_CE[a[0,1].to_sym]
      elsif a =~ TIME_PERIOD_BC_MATCH
        match = TIME_PERIODS_BC[a[0,2].to_sym]
      end
      
      #
      # If the match is
      # not a date range (1900-2000)
      # return the value
      #
      return match if ! match =~ /\d+\-\d+/
      
      # A range was found in the mapping,
      # collect the centuries
      # Looping through each item in range is
      # needed to gather century spans
      range = match.split(/\-/)
      eras = (range[0]..range[1]).collect do |v|
        year_to_century(v)
      end
      eras.uniq
    end
    
    def self.o45_b_label(value)
      # regx to match CE type date code
      ce=%r(^d)
      if value =~ ce
        no_code = value.sub(ce, '')
        dates = yyyymmddhh(no_code)
        return year_to_century(dates.first)
      end
      # regx to match BC type date code
      bc=%r(^c)
      # Convert yyyymmdd to "yyy-mm-dd B.C."
      return yyyymmddhh(value.sub(bc, '')).join('-') + " B.C." if value =~ bc
    end
  end
  
end