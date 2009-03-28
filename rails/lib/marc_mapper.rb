require 'rubygems'
require 'marc' # ruby gem for working with MARC data in Ruby
require 'block_mapper' # the generic mapper class
require 'marc_record_ext.rb' # our custom methods
require 'base64' # so we can base64 encode the marc21 record

class MARCMapper < BlockMapper
  
  def initialize()
    super
    before_each_source_item do |rec,index|
      # add custom methods to each marc record
      rec.extend MARCRecordExt
    end
    # remove ; / . , : and spaces from the end
    cleanup_regexp = /( |;|\/|\.|,|:)+$/
    after_each_mapped_value do |field,v|
      #puts "cleaning up #{field} value(s) before adding to solr..."
      if v.is_a?(String)
        v.gsub(cleanup_regexp, '') # clean this string and return
      elsif v.is_a?(Array)
        v.map{|vv|vv.gsub(cleanup_regexp, '')} # clean each value and return a new array
      else
        v # just return whatever it is
      end
    end
  end
  
  # pass in a path to a marc file
  # a block can be used for logging etc..
  # 
  # mapper.from_marc_file('/path/to/data.mrc') do |mapped_doc|
  #   # do something here... logging etc..
  # end
  #
  # this returns an array of documents (hashes)
  #
  def from_marc_file(marc_file, shared_field_data={}, &blk)
    
    shared_field_data.each_pair do |k,v|
      # map each item in the hash to a solr field
      map k.to_sym, v
    end
    
    map :id do |rec,index|
      rec['001'].value.gsub(" ","").gsub("/","")
    end
    
    map :title_t do |rec,index|
      rec.values_for '245', 'a'
    end
    
    map :sub_title_t do |rec,index|
      rec.values_for '245', 'b'
    end
    
    map :alt_titles_t do |rec,index|
      rec.extract '240:b 700:t 710:t 711:t 440:a 490:a 505:a 830:a'
    end
    
    map :title_added_entry_t do |rec,index|
      rec.values_for '700', 't'
    end
    
    map :author_t do |rec,index|
      rec.extract '100:a 110:a 111:a 130:a 700:a 710:a 711:a'
    end
    
    map :published_t do |rec,index|
      rec.extract '260:a'
    end
    
    map :isbn_t do |rec,index|
      rec.isbn # in MARCRecordExt module
    end
    
    map :material_type_t do |rec,index|
      rec.values_for '300', 'a'
    end

    map :subject_t do |rec,index|
      rec.extract '600:a 610:a 611:a 630:a 650:a 651:a 655:a 690:a'
    end

    map :subject_era_facet do |rec,index|
      rec.extract '650:d 650:y 651:y 655:y'
    end

    map :geographic_subject_facet do |rec,index|
      rec.extract '650:c 650:z 651:a 651:x 651:z 655:z'
    end

    map :language_facet do |rec,index|
      rec.languages # in MARCRecordExt module
    end

    # _display is stored, but not indexed
    # don't store a string, store marc21 so we can read it back out
    # into a MARC::Record object 
    map :marc_display do |rec,index|
      rec.to_xml
    end
    
    map :format_facet do |rec,index|
      rec.format # in MARCRecordExt module
    end
    
    # downcased, format, spaces converted to _
    # This can be used for the partial view mapping
    map :format_code_t do |rec,index|
      rec.format.to_s.downcase.gsub(/ _/, ' ').gsub(/ /, '_')
    end
    
    reader = MARC::Reader.new(marc_file)
    self.run(reader, &blk)
    
  end
  
end