# meant to be mixed into a SolrDocument (Hash/Mash based object)
module Blacklight::Solr::Document::Marc
  # From paramix gem, parameterized mix-ins, let's us refer to the module
  # as Marc[:marc_source_field => "some_field"], and then refer in code to
  # mixin_params[Marc][:marc_source_field]
  require 'paramix'
  include Paramix

  include Blacklight::Solr::Document::MarcExport # All our export_as stuff based on to_marc. 



  def self.extended(document)
    # Register our exportable formats, we inherit these from MarcExport    
    Blacklight::Solr::Document::MarcExport.register_export_formats( document )
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
    @_ruby_marc_obj ||= load_marc
  end


  protected
  def marc_source
    @_marc_source ||= fetch(_marc_source_field)
  end

  def load_marc
      case @marc_type.to_s
        when 'marcxml'
          records = MARC::XMLReader.new(StringIO.new(@marc_data)).to_a
          return records[0]
        when 'marc21'
          return MARC::Record.new_from_marc(@marc_data)          
        else
          raise UnsupportedMarcFormatType.new("Only marcxml and marc21 are supported.")
      end      
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