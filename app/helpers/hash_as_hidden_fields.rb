# Rails Helper methods to take a hash and turn it to form <input type="hidden">
# fields, works with hash nested with other hashes and arrays, standard rails
# serialization style.  Oddly while Hash#to_query will do this for a URL
# query parameters, there seems to be no built in way to do it to create
# hidden form fields instead. 
#
# Code taken from http://marklunds.com/articles/one/314
#
# This is used to serialize a complete current query from current params
# to form fields used for sort and change per-page
module HashAsHiddenFields

  # Writes out zero or more <input type="hidden"> elements, completely
  # representing a hash passed in using Rails-style request parameters
  # for hashes nested with arrays and other hashes. 
  def hash_as_hidden_fields(hash)
    
    hidden_fields = []
    flatten_hash(hash).each do |name, value|
      value = [value] if !value.is_a?(Array)
      value.each do |v|
        hidden_fields << hidden_field_tag(name, v.to_s, :id => nil)          
      end
    end
    
    hidden_fields.join("\n")
  end

  protected
  
  def flatten_hash(hash = params, ancestor_names = [])
    flat_hash = {}
    hash.each do |k, v|
      names = Array.new(ancestor_names)
      names << k
      if v.is_a?(Hash)
        flat_hash.merge!(flatten_hash(v, names))
      else
        key = flat_hash_key(names)
        key += "[]" if v.is_a?(Array)
        flat_hash[key] = v
      end
    end
    
    flat_hash
  end
  
  def flat_hash_key(names)
    names = Array.new(names)
    name = names.shift.to_s.dup 
    names.each do |n|
      name << "[#{n}]"
    end
    name
  end
  
end
