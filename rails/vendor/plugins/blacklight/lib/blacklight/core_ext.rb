# Like deep_merge, except that hash that's merging into the first
# won't override if its values are nil or empty.
module Blacklight::CoreExt
  
  module DeepMergeUnlessBlank
    
    # does what it says it does. Merges in values (recursively),
    # but only replaces with values that are not blank (nil or empty strings)
    def deep_merge_unless_blank(hash)
      target = dup
      hash.each_pair do |key,value|
        if value.respond_to?(:each_pair) and self[key].respond_to?(:each_pair)
          target[key] = target[key].deep_merge_unless_blank(value)
          next
        end
        # only set or override if the target has the key, AND the hash's value is not blank
        target[key] = value unless (target[key] && (value.nil? || value.to_s.empty?))
      end
      target
    end
=begin
    # works on object reference
    def deep_merge_unless_blank!(second)
      second.each_pair do |k,v|
        if self[k].is_a?(Hash) and second[k].is_a?(Hash)
          self[k].deep_merge_unless_blank!(second[k])
        else
          self[k] = second[k] unless second[key].nil?
        end
      end
    end
  
    # idea taken from ActiveSupport  (Hash reverse_merge)
    def reverse_deep_merge_unless_blank(other_hash)
      other_hash.deep_merge_unless_blank(self)
    end
  
    # idea taken from ActiveSupport (Hash reverse_merge!)
    # Performs the opposite of <tt>deep_merge_unless_blank!</tt>, with the keys and values from the first hash taking precedence over the second.
    # Modifies the receiver in place.
    def reverse_deep_merge_unless_blank!(other_hash)
      replace(reverse_deep_merge_unless_blank(other_hash))
    end
=end
    
  end

end

Hash.send :include, Blacklight::CoreExt::DeepMergeUnlessBlank