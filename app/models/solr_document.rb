class SolrDocument
  include Blacklight::Solr::Document
  #include Blacklight::Solr::Document::Marc

  # DEPRECATED 
  cattr_accessor :marc_format_type
  cattr_accessor :marc_source_field

  # DEPRECATED
  def marc
    warn "[DEPRECATION] aDocument.marc is deprecated.  Please use aDocument.respond_to?(:to_marc) / aDocument.respond_to?(:marc),  or aDocument.exports_as.keys.include?(:some_format) / aDocument.export_as(:some_format) instead."

    nil
  end
  
  def self.marc_format_type=(type)
    warn "[DEPRECATION] SolrDocument.marc_format_type and .marc_source_field are deprecated. Please use SolrDocument.use_extension to register the Marc extension instead"
    @@marc_format_type = type
    if marc_source_field
      # We have the complete set
      use_extension( Blacklight::Solr::Document::Marc[ :marc_source_field => marc_source_field, :marc_format_type => type ]   )  { |document| document.key?( marc_source_field ) }
    end    
  end

  def self.marc_source_field=( source_field)
    @@marc_source_field = source_field
    if marc_format_type
      # We have the complete set! 
      use_extension( Blacklight::Solr::Document::Marc[ :marc_source_field => source_field, :marc_format_type => marc_format_type ]   )  { |document| document.key?( source_field ) }
    end
  end

  
end