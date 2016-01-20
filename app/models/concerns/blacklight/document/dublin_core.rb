# frozen_string_literal: true
require 'builder'

# This module provide Dublin Core export based on the document's semantic values
module Blacklight::Document::DublinCore

  def self.extended(document)
    # Register our exportable formats
    Blacklight::Document::DublinCore.register_export_formats( document )
  end

  def self.register_export_formats(document)
    document.will_export_as(:xml)
    document.will_export_as(:dc_xml, "text/xml")
    document.will_export_as(:oai_dc_xml, "text/xml")
  end

  def dublin_core_field_names
    [:contributor, :coverage, :creator, :date, :description, :format, :identifier, :language, :publisher, :relation, :rights, :source, :subject, :title, :type]
  end

  # dublin core elements are mapped against the #dublin_core_field_names whitelist.
  def export_as_oai_dc_xml
    xml = Builder::XmlMarkup.new
    xml.tag!("oai_dc:dc",
             'xmlns:oai_dc' => "http://www.openarchives.org/OAI/2.0/oai_dc/",
             'xmlns:dc' => "http://purl.org/dc/elements/1.1/",
             'xmlns:xsi' => "http://www.w3.org/2001/XMLSchema-instance",
             'xsi:schemaLocation' => %{http://www.openarchives.org/OAI/2.0/oai_dc/ http://www.openarchives.org/OAI/2.0/oai_dc.xsd}) do
      self.to_semantic_values.select { |field, values| dublin_core_field_name? field  }.each do |field,values|
        Array.wrap(values).each do |v|
          xml.tag! "dc:#{field}", v
        end
      end
    end
    xml.target!
  end

  alias_method :export_as_xml, :export_as_oai_dc_xml
  alias_method :export_as_dc_xml, :export_as_oai_dc_xml

  private

  def dublin_core_field_name? field
    dublin_core_field_names.include? field.to_sym
  end
end
