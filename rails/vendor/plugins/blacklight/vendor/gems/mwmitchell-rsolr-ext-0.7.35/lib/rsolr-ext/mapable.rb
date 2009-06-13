# A module that provides method mapping capabilities.
# The basic idea is to pass in a hash to the #map method,
# the map method then goes through a list of keys (MAPPED_PARAMS) to
# be processed. Each key name can match a key in the input hash.
# If there is a match, a method by the name of "map_#{key}" is
# called with the following args: input[key], output_hash
# The method is responsible for processing the value.
# The return value from the method is not used.
#
# For example: if the mapped params list has :query,
# there should be a method like: map_query(input_value, output_hash)
# The output_hash is the final hash the the #map method returns,
# so whatever you do to output_hash gets returned in the end.
module RSolr::Ext::Mapable
  
  # accepts an input hash.
  # prepares a return hash by copying the input.
  # runs through all of the keys in MAPPED_PARAMS.
  # calls any mapper methods that match the current key in MAPPED_PARAMS.
  # The mapped keys from the input hash are deleted.
  # returns a new hash.
  def map(input)
    result = input.dup
    self.class::MAPPED_PARAMS.each do |meth|
      input_value = result.delete(meth)
      next if input_value.to_s.empty?
      send("map_#{meth}", input_value, result)
    end
    result
  end
  
  # creates an array where the "existing_value" param is first
  # and the "new_value" is the last.
  # All empty/nil items are removed.
  # the return result is either the result of the
  # array being joined on a space, or the array itself.
  # "auto_join" should be true or false.
  def append_to_param(existing_value, new_value, auto_join=true)
    values = [existing_value, new_value]
    values.delete_if{|v|v.nil?}
    auto_join ? values.join(' ') : values.flatten
  end
  
end