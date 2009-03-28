
# MARC::Record helpers

# This module gets mixed into each MARC::Record instance

require 'field_maps'

module MARCRecordExt
  
  # input is a string in the format of: field:subfield
  # multiple fields can be given, use a single space to separate
  # example: record.extract '245:a 245:b'
  def extract(input, regexp=nil)
    hash = {}
    input.split(' ').each do |item|
      k,v = item.split(':')
      next unless k
      hash[k]||=[]
      hash[k] << v if v
    end
    hash.map do |field,subfields|
      values_for(field, subfields, regexp)
    end.flatten
  end
  
  # This methods returns a single dimensional array of values for subfields (it also removes blank values)
  # if subs is specified, only the matching subfields are returned
  # if subs is nil, the all subfields are returned
  # the value_regx can be used to match the value of the subfield
  #
  # =example: values_for '045', [:a]
  #
  # =parameters
  # field_name - '045' etc.
  # subs - [:a, :b] etc.
  # value_regx - a Regexp
  def values_for(field_name, subs=nil, value_regx=nil)
    subs ||= []
    subs = [subs] unless subs.is_a?(Array)
    self.fields.collect do |field|
      if field.tag==field_name and ! field.value.to_s.empty?
        field.subfields.collect do |subfield|
          next if ! subs.empty? and ! subs.include?(subfield.code)
          v = value_regx ? subfield.value.match(value_regx) : subfield.value
          v.empty? ? nil : v
        end
      end
    end.flatten.uniq.reject{|v|v.to_s.empty?}
  end
  
  # http://woss.name/2005/09/09/isbn-validation-part-2
  def valid_isbn?(isbn, c_map = '0123456789X')
    sum = 0
    return unless isbn
    match = isbn[0..-2].to_s.scan(/\d/)
    match.each_with_index do |c,i|
      sum += c.to_i * (i+1)
    end
    isbn[-1] == c_map[sum % c_map.length]
  end
  
  # extracts valid isbns
  def isbn
    values = self.extract('020:a')
    # go through each value
    values.select do |v| # "select" collects values only if the last line of this block is true
      # split on a space, grab the first
      isbn = v.to_s.split(' ').first
      # is it valid?
      valid_isbn?(isbn)
    end
  end
  
  # returns the mapped language value
  def languages
    values = [self['008'].value[35..37]]
    values += self.extract('041:a 041:d')
    values.uniq!
    mapped = values.map{|code| FieldMaps::LANGUAGE[code] }
    mapped.reject{|v| v.to_s.empty? }
  end
  
  # http://www.itsmarc.com/crs/Bib0021.htm#Leader_06_Definition
  def format
    char_6 = self.leader[6...7]
    char_7 = self.leader[7...8]
    if char_6 == 'a' and %W(a c d m).include? char_7
      code = 'a'
    elsif %W(b s).include? char_7
      code = 'serials'
    else
      code = char_6
    end
    FieldMaps::FORMAT[code] || 'Unknown'
  end
  
end