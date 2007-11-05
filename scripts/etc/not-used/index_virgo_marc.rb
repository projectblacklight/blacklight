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



require 'optparse'
require 'rubygems'
require 'solr'
require 'marc'

# IS THIS ACTUALLY USED ANYWHERE???
$KCODE = 'UTF8'

SKIPPED_LOCATIONS = ['UL-PRESERV','UNKNOWN','LOST','LOST-NRO','DISCARD','WITHDRAWN','UL-PRNTSVS','BARRED','BURSARED','LOST-PAID',
  'LOSTCLOSED','ORD-CLOSED','SE-TS-OFF','LOST-ASSUM','ATSEA-STKS','LOST-CLAIM','ATSEA-RSRV','LAW-FACOFF','LAW-PAID','HS-BD96-97',
  'HS-BD97-98','HS-BD98-99','HS-BD99-00','HS-BD2001','HS-BD2002','HS-BD2003','HS-BD2004','HS-BD2005','HS-CLENP00','EQUIPMENT',
  'HS-WD96/97','HS-WD98/99','HS-WD99/00','HS-WD2001','HS-WD2002','HS-WD2003','HS-WD2004','HS-WD2005','HS-WED9798','HS-WED2001',
  'HS-WED2002','HS-WTHDRAW','UL-NOTHELD','UL-CATDEPT','UL-ACQDEPT','UL-ILSDEPT','UL-SYSDEPT','UL-ADMIN','UL-SS-DEPT','UL-HUMDEPT',
  'UL-RISDEPT','UL-SC-DEPT','UL-FA-DEPT','UL-CL-DEPT','UL-ED-DEPT','UL-SE-DEPT','UL-SUPPORT','RSRVSHADOW','CL-STORAGE','ORD-CANCLD',
  'HS-WD97/98','HS-COVLOC']

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

RECORDING_FORMAT_LABELS = {
  'CD' => %W(MUSIC-CD RSRV-CD AUDIO-CD),
  'Cassette' => %W(AUDIO-CASS MUSIC-CASS RSRV-CASS RSRV-CAS2D AUDIOJRNL),
  'LP' => %W(IVY-LP MUSIC-LP),
  'Open Reel Tape' => %W(OPENREEL),
  'DVD' => %W(VIDEO-DVD),
  'VHS' => %W(VIDEO-CASS RSRV-VCASS),
  'Laser Disc' => %W(VIDEO-DISC RSRV-VDISC)
}

#
# The mapping (acts as the schema) is passed to an instance of MarcMapper (below)
# How the value types of the mapping are used:
# String: the string is used as is
# Proc: The Proc is called (passed a MARC::Record instance) and returns a string
# Symbol: The MarcMapper.field_data(MARC::Record r, String field) method is called
# Enumerable: Each item is treated as a key=>field and mapped again for each item
#             
#
mapping = {
  # :solr_field_name => String
  # :solr_field_name => Array of Strings
  # :solr_field_name => Proc  [Proc operates on record]
  #    String = 3 digit control field number or 3 digit data field number + subfield letter


  # TODO: Extract sort fields: author, title, date (first value of each): _sort and _sort_i
  # TODO: hardcode field names without suffixes into schema

  # The Control Number field (001)
  :id => Proc.new do |r|    # TODO: namespace the id, something like "catalog:u1"
    # There are multiple '001' items, only use the one that starts with 'u'
    extract_record_data(r,:'001').find {|f| f =~ /^u/}
  end,
  
  :marc_display => Proc.new {|r| r.to_marc },
  
  :author_text => :'100a',
  
  # These 2 fields should be weighted heavier during querying
  # Title Statement/Title Proper
  :title_text => :'245a',
  # Uniform Title/Uniform Title
  :uniform_title_text => :'240a',
  
  :marc_text => Proc.new {|r| r.to_s },
  
  :subject_era_facet => [:'650d', :'650y', :'651y', :'655y'],
  
  :topic_form_genre_facet => Proc.new do |r|
    extract_record_data(r, :'650a').collect + 
    extract_record_data(r, :'650b').collect + 
    extract_record_data(r, :'650x').collect + 
    extract_record_data(r, :'655a').collect
  end,
  
  #:subject_topic_facet => [:'650a', :'650b', :'650x'],
  #:subject_genre_facet => [:'600v', :'610v', :'611v', :'650v', :'651v', :'655a'],
  
  :subject_geographic_facet => [:'650c', :'650z', :'651a', :'651x', :'651z', :'655z'],
  
  # index year, but no facet
  #:year_facet => Proc.new do |r|  # TODO: pull from 008 instead
  #  extract_record_data(r,:'260c').collect {|f| f.scan(/\d\d\d\d/)}.flatten
  #end,
  
  :year_multisort_i => Proc.new do |r|  # TODO: pull from 008 instead
    extract_record_data(r,:'260c').collect {|f| f.scan(/\d\d\d\d/)}.flatten
  end,
  
  :call_number_facet => Proc.new { |r| extract_record_data(r, :'999a').collect{|callnum| callnum[0..1]}.uniq },
  
  # TODO - Don't display LOST, LOSTCLOSED etc. in location facet
  :location_facet => [:'999k', :'999l'],
  
  
  ############################################
  #:library_facet => :'999m',
  
  :library_facet => Proc.new do |r|
     labels = {
        'Alderman' => %W(ALDERMAN),
        'Clemons' => %W(CLEMONS),
        'Ivy Annex' => %W(IVY IVY ),
        'Fine Arts' => %W(FINE-ARTS),
        'Robertson Media Center' => %W(MEDIA-CTR),
        'Astronomy' => %W(ASTRONOMY),
        'Music' => %W(MUSIC),
        'Brown SEL' => %W(SCI-ENG),
        'Special Collections' => %W(SPEC-COLL),
        'Darden Business School' => %W(DARDEN),
        'Health Sciences' => %W(HEALTHSCI)
        
      }
        format = extract_record_data(r, :'999m').first.strip
        #puts format
        match = labels.select do |k,v|
          #puts "k = #{k}"
          #puts "v = #{v}"
          v.include? format
        end
        match.nil? ? nil : match.first.first
    end,
  
  #:library_facet => "fake!",
  
  ############################################
  
  #:format_facet => :'999t',
  :format_facet => Proc.new do |r|
     labels = {
        'Book' => %W(BOOK IVY-BOOK RAREBOOK BOOK-NC BOOK-30DAY RSRV-BOOK BOOK-1DAY RSRV-BK-NC ILL-BOOK REFERENCE RSRV-BK-2H JUV-BOOK),
        'Online Resource' => %W(INTERNET E-JRNL E-BOOK),
        'Musical Score' => %W(MUSI-SCORE IVY-SCORE MUSCORE-NC),
        'Print Journal' => %W(BOUND-JRNL IVY-JRNL BD-JRNL-NC CUR-PER JRNL1WK JRNL2WK JRNL4HR RAREJRNL),
        'Archives' => %W(ARCHIVES MANUSCRIPT),
        'Music CD' => %W(MUSIC-CD),
        'Music' => %W(MUSIC),
        'Microfiche' => %W(MICROFICHE IVY-MFICHE),
        'Equipment' => %W(HS-DVDPLYR EQUIP-3DAY CELLPHONE CALCULATOR LCDPANEL HSLAPTOP PROJSYSTEM HSWIRELESS EQUIP-2HR DIGITALCAM AUDIO-VIS LAPTOP EQUIP-3HR CAMCORDER AV-7DAY)
      }
        format = extract_record_data(r, :'999t').first.strip
        #puts format
        
        if(format=="MUSI-SCORE")
          puts "!!!!!!!!"
          puts "leader: " + r.leader
          puts "format code: " + format_code(r)
          puts is_score?(r) 
          puts "!!!!!!!!!"
        end
        
        match = labels.select do |k,v|
          #puts "k = #{k}"
          #puts "v = #{v}"
          v.include? format
        end
        match.nil? ? nil : match.first.first
    end,
  
  
  ############################################
  
  ## recordings and scores facet
  ## to do: Recordings doesn't work
  :recordings_and_scores_facet => Proc.new do |r|
  
    if is_score?(r) 
      "Scores"
    elsif is_recording?(r)
      "Recordings"
    else
      "neither"
    end
  
  end, 
  
  ############################################
  
  
  :instrument_facet => Proc.new do |r|
    extract_record_data(r, :'048a').collect{|f| f[0..1]}.uniq
  end,
  
  :recording_format_facet => Proc.new do |r|
    if is_recording?(r)
      t = extract_record_data(r, :'999t')
      match = RECORDING_FORMAT_LABELS.select do |k,v|
        t.select do |cat|
          v.include? cat.strip
        end.size > 0
      end
      matched_labels = match.collect {|i| i.first}
      matched_labels.to_a.empty? ? nil : matched_labels
    end
  end,
  
  :recording_type_facet => Proc.new do |r|
    if is_musical_recording?(r)
      'Musical'
    elsif is_non_musical_recording?(r)
      'Non-Musical'
    end
  end,
  
  :music_category_facet => Proc.new do |r|
    call = extract_record_data(r, :'999a').find do |v|
      v =~ /^m[lt23\s]+/i
    end
    value = call.to_s[0..1].strip
    value.empty? ? nil : value
  end,
  
  :language_facet => Proc.new {|r| extract_record_data(r, :'008').collect{|f| f[35..37]}.uniq },
  
  :source_facet => Proc.new do |r|
    sub_field=extract_record_data(r, :'999a')
    sub_field.any? {|val| val =~ /^m/i } ? 'music' : 'other'
  end,
  
  :composition_era_facet => Proc.new do |r|
    eras=[]
    unless r['045'].nil?
      o45 = r['045']
      a=o45.find_all {|r| r.code =='a'}
      b=o45.find_all {|r| r.code =='b'}
      b.each do |bval|
        puts 'SETTING 045 $B DATE'
        eras << o45_b_label(bval.value)
      end
      a.each do |aval|
        puts 'SETTING 045 $A DATE'
        eras << o45_a_label(aval.value)
      end
    end
    eras.uniq
  end
}

require 'linguistics'
Linguistics::use(:en)
def year_to_century(year)
  puts 'converting year to century: '+ year.to_s
  century = ((year.to_i/100)+1)
  puts 'century == ' + century.to_s
  century.en.ordinal + ' Century'
end

def yyyymmddhh(b)
  b.scan(/(\d{4})(\d{2})?(\d{2})?/).flatten
end

def o45_a_label(a)
  puts "********** o45_a_label A value == #{a}"
  match = nil
  if a =~ O45_A_TIME_PERIOD_CE_MATCH
    puts "A CE TIME"
    match = O45_A_TIME_PERIODS_CE[a[0,1].to_sym]
  elsif a =~ O45_A_TIME_PERIOD_BC_MATCH
    puts "A BC TIME"
    match = O45_A_TIME_PERIODS_BC[a[0,2].to_sym]
  end
  puts "A VALUE MATCH == #{match}"
  return match if ! match =~ /\d+\-\d+/
  eras=[]
  range = match.split(/\-/)
  (range[0]..range[1]).each do |v|
    eras << year_to_century(v)
  end
  eras.uniq
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

SOLR_CONFIG={
  :solr_url => 'http://localhost:8983/solr',
  :debug=>false,
  :timeout=>120
}

DATA_DIR='../data/marc/virgo'
MARC_FILENAME=Dir["#{DATA_DIR}/*.mrc"].entries.first

def format_code(record)
  record.leader[6,1].to_s
end

def is_score?(record)
  format_code(record) =~ /^[cd]+$/i
end

def is_printed_score?(record)
  format_code(record) == 'c'
end

def is_manusript_score?(record)
  format_code(record) == 'd'
end

def is_sound_recording?(record)
  format_code(record) =~ /^[ji]+$/i
end

def is_recording?(record)
  format_code(record) =~ /^[jig]+$/i
end

def is_video_recording?(record)
  format_code(record) == 'g'
end

def is_musical_recording?(record)
  format_code(record) == 'j'
end

def is_non_musical_recording?(record)
  format_code(record) == 'i'
end

#
# Returns an array of strings
# from field values of a MARC::Record record instance
# where the marc record field matches the field argument
# If the field arg is < 010,
# return the value of that field's combined sub-fields
#
def extract_record_data(record, field)
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


class MarcMapper < Solr::Importer::Mapper
  
  #alias :orig_map :map
  #def map(*args)
  #  r = orig_map(*args)
  #end
  
  def map(orig_data)
    mapped_data = {}
    @mapping.each do |solr_name, field_mapping|
      value = mapped_field_value(orig_data, field_mapping)
      mapped_data[solr_name] = value if value
    end
    mapped_data
  end
  
  #
  # If field value in map above is a symbol
  # this method gets called.
  # See Solr::Importer::Mapper.mapped_field_value
  #
  def field_data(record, field)
    extract_record_data(record, field)
  end
end

#
# "data source" - filters out unwanted records and can filter fields
#
class FilteringMarcReader
  
  def initialize(marc_filename)
    @reader = MARC::ForgivingReader.new(marc_filename)
  end

  def each
    total=0
    @reader.each do |record|
      if total >= 1000
        return
      end
      if in_valid_location?(record)
        total += 1
        # if in bad location (LOST), skip
        
        filter_999_o_value(record)
        puts "VALID: #{record['001']}"
        yield record
      else
        puts "SKIPPED: #{record['001']}"
      end
    end
  end
  
  # Only process records that have at least one
  # location not in the SKIPPED_LOCATIONS list
  # TODO: clear the skipped locations so they do not become facets
  def in_valid_location?(record)
    locations = extract_record_data(record, :'999k') + extract_record_data(record, :'999l')
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

def do_index(reader, mapper)
  count = 0
  indexer = Solr::Indexer.new(reader, mapper, SOLR_CONFIG)
  result = indexer.index do |orig_data, solr_document|
    count = count + 1
    puts "Indexing record # #{count}"
  end
  puts result ? 'COMMIT OK' : 'COMMIT FAILED'
end

DEBUG=true
def log(msg)
  puts ("*" * 10) + msg if DEBUG
end

puts "#{Time.new}: Indexing #{MARC_FILENAME}..."
reader = FilteringMarcReader.new(MARC_FILENAME)
mapper = MarcMapper.new(mapping)
do_index(reader, mapper)