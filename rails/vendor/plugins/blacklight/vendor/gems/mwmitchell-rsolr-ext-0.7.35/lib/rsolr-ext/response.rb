module RSolr::Ext::Response
  
  autoload :Facets, 'rsolr-ext/response/facets'
  autoload :Docs, 'rsolr-ext/response/docs'
  autoload :Spelling, 'rsolr-ext/response/spelling'
  
  class Base < Mash
    
    def header
      self['responseHeader']
    end
    
    def params
      header['params']
    end
    
    def ok?
      header['status'] == 0
    end
    
  end
  
  # 
  class Standard < Base
    
    def initialize(*args)
      super(*args)
      extend Docs
      extend Facets
      extend Spelling
    end
    
    def response
      self[:response]
    end
    
    # short cut to response['numFound']
    def total
      response[:numFound]
    end
    
  end
  
  class Dismax < Standard
    
  end
  
  # 
  class Luke < Base
    
    # Returns an array of fields from the index
    # An optional rule can be used for "grepping" field names:
    # field_list(/_facet$/)
    def field_list(rule=nil)
      fields.select do |k,v|
        rule ? k =~ rule : true
      end.collect{|k,v|k}
    end
    
    def fields
      self['fields']
    end

  end# end Luke
  
  # Update
  class Update < Base
    
  end
  
end