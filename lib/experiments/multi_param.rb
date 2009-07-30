#
# MultiParam is a class makes working with array values in a url easier and better looking than the standard Rails syntax: []
# ?f.location_facet=Value 1|Value 2|Value 3
#

class MultiParam < Hash
  
  #
  #
  #
  attr :fields
  
  #
  #
  #
  def initialize(input_params, fields=[])
    @input_params = input_params
    @fields = fields
    self.merge! parse(@input_params)
  end
  
  def to_query
    self.inject({}) do |acc,(k,v)|
      acc.merge({k=>v.join('|')})
    end
  end
  
  def has?(field, value=nil)
    return has_key?(field) unless value
    has_key?(field) and self[field].include?(value)
  end
  
  def add(field, value)
    mp = dupme
    mp[field]||=[]
    mp[field] << value unless mp[field].include?(value)
    mp
  end
  
  def remove(field, value=nil)
    mp = dupme
    return mp unless has_key?(field)
    if value
      mp[field] -= [value] if mp[field].include?(value)
      mp.delete(field) if mp[field].size==0 # remove empty/blank params
    else
      mp.delete field
    end
    mp
  end
  
  def toggle(field, value)
    mp = dupme
    return mp unless has_key?(field)
    return mp unless mp[field].include?(value)
    toggle_value(mp[field], value)
    mp
  end
  
  protected
  
  def toggle_value(src, value)
    src.each_with_index do |v,i|
      src[i] = v == value ? (v[0..1]=='-' ? v[1..-1] : "-#{v}") : v
    end
  end
  
  def dupme
    self.class.new(@input_params, @fields)
  end
  
  def parse(input_params)
    input_params.inject({}) do |acc,(k,v)|
      if @fields.include?(k)
        acc[k]=v.split('|')
      end
      acc
    end
  end
  
end