module Blacklight::Solr::Document::EAD
  
  def self.included(base)
    base.cattr_accessor :ead_source_field
  end
  
  def ead
    @ead ||= (
      Document.new(self)
    ) if key? self.class.ead_source_field
  end
  
  class Document
    
    attr :solr_doc
    
    def initialize(solr_doc)
      @solr_doc = solr_doc
    end
    
    def toc_file
      File.join(RAILS_ROOT, 'tmp', 'cache', 'json-toc', "#{@solr_doc[:base_id_s]}.json")
    end
    
    def toc
      ActiveSupport::JSON.decode( File.read(self.toc_file) )
    end
    
  end
  
end