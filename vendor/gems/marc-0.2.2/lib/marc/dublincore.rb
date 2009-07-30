module MARC
  
  # A class for mapping MARC records to Dublin Core
  
  class DublinCore

    def self.map(record)
      dc_hash = Hash.new
      dc_hash['title'] = get_field_value(record['245']['a'])

      # Creator
      [100, 110, 111, 700, 710, 711, 720].each do |field|
        dc_hash['creator'] ||= []
        dc_hash['creator'] << get_field_value(record[field.to_s])
      end

      # Subject
      [600, 610, 611, 630, 650, 653].each do |field|
        dc_hash['subject'] ||= []
        dc_hash['subject'] << get_field_value(record[field.to_s])
      end

      # Description
      [500..599].each do |field|
        next if [506, 530, 540, 546].include?(field)
        dc_hash['description'] ||= []
        dc_hash['description'] << get_field_value(record[field.to_s])
      end

      dc_hash['publisher'] = get_field_value(record['260']['a']['b']) rescue nil
      dc_hash['date'] = get_field_value(record['260']['c']) rescue nil
      dc_hash['type'] = get_field_value(record['655']) 
      dc_hash['format'] = get_field_value(record['856']['q']) rescue nil
      dc_hash['identifier'] = get_field_value(record['856']['u']) rescue nil
      dc_hash['source'] = get_field_value(record['786']['o']['t']) rescue nil
      dc_hash['language'] = get_field_value(record['546'])

      dc_hash['relation'] = []
      dc_hash['relation'] << get_field_value(record['530'])
      [760..787].each do |field|
        dc_hash['relation'] << get_field_value(record[field.to_s]['o']['t']) rescue nil
      end

      [651, 752].each do |field|
        dc_hash['coverage'] ||= []
        dc_hash['coverage'] << get_field_value(record[field.to_s])
      end

      [506, 540].each do |field|
        dc_hash['rights'] ||= []
        dc_hash['rights'] << get_field_value(record[field.to_s])
      end
      
      dc_hash.keys.each do |key| 
        dc_hash[key].flatten! if dc_hash[key].respond_to?(:flatten!)
        dc_hash[key].compact! if dc_hash[key].respond_to?(:compact!)
      end
      
      dc_hash
    end
      
    def self.get_field_value(field)
      return if field.nil?
      
      if !field.kind_of?(String) && field.respond_to?(:each)
        values = []
        field.each do |element|
          values << get_field_value(element)
        end
        values
      else
        return field if field.kind_of?(String)
        return field.value if field.respond_to?(:value)
      end
    end
    
  end
end

