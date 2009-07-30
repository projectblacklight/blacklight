# a module to help the creation of solr queries.
module RSolr::Ext::Request::Queryable
  
  # Wraps a string around double quotes
  def quote(value)
    %("#{value}")
  end
  
  # builds a solr range query from a Range object
  def build_range(r)
    "[#{r.min} TO #{r.max}]"
  end
  
  # builds a solr query fragment
  # if "quote_string" is true, the values will be quoted.
  # if "value" is a string/symbol, the #to_s method is called
  # if the "value" is an array, each item in the array is 
  # send to build_query (recursive)
  # if the "value" is a Hash, a fielded query is built
  # where the keys are used as the field names and
  # the values are either processed as a Range or
  # passed back into build_query (recursive)
  def build_query(value, quote_string=false)
    case value
    when String,Symbol
      quote_string ? quote(value.to_s) : value.to_s
    when Array
      value.collect do |v|
        build_query(v, quote_string)
      end.flatten
    when Hash
      return value.collect do |(k,v)|
        if v.is_a?(Range)
          "#{k}:#{build_range(v)}"
        # If the value is an array, we want the same param, multiple times (not a query join)
        elsif v.is_a?(Array)
          v.collect do |vv|
            "#{k}:#{build_query(vv, quote_string)}"
          end
        else
          "#{k}:#{build_query(v, quote_string)}"
        end
      end.flatten
    end
  end
  
end