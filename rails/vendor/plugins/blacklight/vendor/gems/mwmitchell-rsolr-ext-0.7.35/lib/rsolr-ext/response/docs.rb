module RSolr::Ext::Response::Docs
  
  module Accessible
    
    # Helper method to check if value/multi-values exist for a given key.
    # The value can be a string, or a RegExp
    # Multiple "values" can be given; only one needs to match.
    # 
    # Example:
    # doc.has?(:location_facet)
    # doc.has?(:location_facet, 'Clemons')
    # doc.has?(:id, 'h009', /^u/i)
    def has?(k, *values)
      return if self[k].nil?
      return true if self.key?(k) and values.empty?
      target = self[k]
      if target.is_a?(Array)
        values.each do |val|
          return target.any?{|tv| val.is_a?(Regexp) ? (tv =~ val) : (tv==val)}
        end
      else
        return values.any? {|val| val.is_a?(Regexp) ? (target =~ val) : (target == val)}
      end
    end

    # helper
    # key is the name of the field
    # opts is a hash with the following valid keys:
    #  - :sep - a string used for joining multivalued field values
    #  - :default - a value to return when the key doesn't exist
    # if :sep is nil and the field is a multivalued field, the array is returned
    def get(key, opts={:sep=>', ', :default=>nil})
      if self.key? key
        val = self[key]
        (val.is_a?(Array) and opts[:sep]) ? val.join(opts[:sep]) : val
      else
        opts[:default]
      end
    end

  end
  
  module Pageable
    
    attr_accessor :start, :per_page, :total
    
    # Returns the current page calculated from 'rows' and 'start'
    # WillPaginate hook
    def current_page
      return 1 if start < 1
      per_page_normalized = per_page < 1 ? 1 : per_page
      @current_page ||= (start / per_page_normalized).ceil + 1
    end
    
    # Calcuates the total pages from 'numFound' and 'rows'
    # WillPaginate hook
    def total_pages
      @total_pages ||= per_page > 0 ? (total / per_page.to_f).ceil : 1
    end
    
    # returns the previous page number or 1
    # WillPaginate hook
    def previous_page
      @previous_page ||= (current_page > 1) ? current_page - 1 : 1
    end
    
    # returns the next page number or the last
    # WillPaginate hook
    def next_page
      @next_page ||= (current_page == total_pages) ? total_pages : current_page+1
    end
    
    def has_next?
      current_page < total_pages
    end
    
    def has_previous?
      current_page > 1
    end
    
  end
  
  def self.extended(base)
    d = base['response']['docs']
    d.extend Pageable
    d.each do |item|
      item.extend Accessible
    end
    d.per_page = base['responseHeader']['params']['rows'].to_s.to_i
    d.start = base['response']['start'].to_s.to_i
    d.total = base['response']['numFound'].to_s.to_i
  end
  
  def docs
    response['docs']
  end
  
end