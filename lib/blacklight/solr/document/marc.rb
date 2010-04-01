# meant to be mixed into a SolrDocument (Hash/Mash based object)
module Blacklight::Solr::Document::Marc
  # From paramix gem, parameterized mix-ins, let's us refer to the module
  # as Marc[:marc_source_field => "some_field"], and then refer in code to
  # mixin_params[Marc][:marc_source_field]
  require 'paramix'
  include Paramix

  # translation methods that take from #to_marc and export_as various
  # things.
  #include MarcExport


  def self.extended(document)
    # Register our exportable formats, we inherit these from MarcExport
    document.will_export_as(:xml)
    
    document.will_export_as(:marc, "application/marc")
    # marcxml content type: 
    # http://tools.ietf.org/html/draft-denenberg-mods-etc-media-types-00
    document.will_export_as(:marcxml, "application/marcxml+xml")

    
  end

  # DEPRECATED. Here for legacy purposes, but use to_marc instead. Or
  # internally, use the protected _marc_helper method to get the
  # (somewhat confusingly named)  Blacklight::Marc::Document helper object.
  #
  # This method gets attached to a SolrDocument.
  # it uses the marc_source_field and marc_format_type
  # class attributes to create the Blacklight::Marc::Document instance.
  # Only returns a Blacklight::Marc::Document instance if
  # the self.class.marc_source_field key exists.
  def marc
    warn "[DEPRECATION] aDocument.marc is deprecated.  Please use aDocument.respond_to?(:to_marc) / aDocument.respond_to?(:marc),  or aDocument.exports_as.keys.include?(:some_format) / aDocument.export_as(:some_format) instead."

    _marc_helper
  end  

  # ruby-marc object
  def to_marc
    _marc_helper.marc
  end

  # marc21 string
  def export_as_marc
    _marc_helper.marc.to_marc
  end

  # marcxml string
  def export_as_marcxml
    _marc_helper.marc.to_xml.to_s
  end

  # export marc xml as .xml, although for non-marc docs
  # this might be something else, so now sure how useful it is
  # for a client. 
  def export_as_xml
    export_as_marcxml
  end

  protected
  def marc_source
    @_marc_source ||= fetch(_marc_source_field)
  end
  


  
  def _marc_helper
    @_marc_helper ||= (
      Blacklight::Marc::Document.new fetch(_marc_source_field), _marc_format_type )
  end

  def _marc_source_field
    if (respond_to?(:mixin_params))
      mixin_params[Blacklight::Solr::Document::Marc][:marc_source_field]
    else    
      raise TypeError.new("marc_source_field not defined. You must refer to module with parameters as Blacklight::Solr::Document::Marc[:marc_source_field => solr_field_name, :marc_format_type => format].")
    end
  end

  def _marc_format_type
    if (respond_to?(:mixin_params))
      mixin_params[Blacklight::Solr::Document::Marc][:marc_format_type]
    else
      raise TypeError.new("marc_format_type not defined. You must refer to module with parameters as Blacklight::Solr::Document::Marc[:marc_source_field => solr_field_name, :marc_format_type => format] please.")   
    end
  end
  
end