module Blacklight::Solr::Document::DublinCore
  def self.extended(document)
    # Register our exportable formats, we inherit these from MarcExport    
    Blacklight::Solr::Document::DublinCore.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:xml)
    document.will_export_as(:dc_xml, "text/xml")
    document.will_export_as(:oai_dc_xml, "text/xml")
  end

  def to_oai_dc_xml
    export_as('oai_dc_xml')
  end

  def export_as_oai_dc_xml
    xml = Builder::XmlMarkup.new
    xml.tag!("oai_dc:dc",
             'xmlns:oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
             'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
             'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
             'xsi:schemaLocation' => %{http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd}) do
       self.to_semantic_values.select { |field, values| field =~ /^dc:/ }.each do |field,values|
         values.each do |v|
           xml.tag! field.to_s, v
         end
       end
     end
    xml.target!
  end

  alias_method :export_as_xml, :export_as_oai_dc_xml
  alias_method :export_as_dc_xml, :export_as_oai_dc_xml

end
