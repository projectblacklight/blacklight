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
    
    warn "[DEPRECATION] SolrDocument.marc_format_type and .marc_source_field are deprecated. Please instead use SolrDocument.extension_parameters[:marc_format_type] = type, and use_extension to register the Marc extension instead"
    extension_parameters[:marc_format_type] = type

    # Auto-register the Marc extension if both source_field and format_type are
    # set, to mimic old deprecated legacy behavior. 
    if (extension_parameters[:marc_source_field] && extension_parameters[:marc_format_type])     
      use_extension( Blacklight::Solr::Document::Marc)  { |document| document.key?( extension_parameters[:marc_source_field] ) }
    end
  end

  def self.marc_source_field=( source_field)
    
    warn "[DEPRECATION] SolrDocument.marc_format_type and .marc_source_field are deprecated. Please instead use SolrDocument.extension_parameters[:marc_source_field] = field, and use_extension to register the Marc extension instead"
    
    extension_parameters[:marc_source_field] = source_field

    # Auto-register the Marc extension if both source_field and format_type are
    # set, to mimic old deprecated legacy behavior. 
    if (extension_parameters[:marc_source_field] && extension_parameters[:marc_format_type])     
      use_extension( Blacklight::Solr::Document::Marc)  { |document| document.key?( extension_parameters[:marc_source_field] ) }
    end
  end

  
end