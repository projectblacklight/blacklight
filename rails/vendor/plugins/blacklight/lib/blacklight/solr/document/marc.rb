# meant to be mixed into a SolrDocument (Hash/Mash based object)
module Blacklight::Solr::Document::Marc
  
  # adds the marc_source_field and marc_format_type
  # class accessors to whatever includes this module (SolrDocument.marc_source_field = 'xxx')
  def self.included(base)
    base.cattr_accessor :marc_source_field
    base.cattr_accessor :marc_format_type
  end
  
  # This method gets attached to a SolrDocument.
  # it uses the marc_source_field and marc_format_type
  # class attributes to create the Blacklight::Marc::Document instance.
  # Only returns a Blacklight::Marc::Document instance if
  # the self.class.marc_source_field key exists.
  def marc
    @marc ||= (
      Blacklight::Marc::Document.new fetch(self.class.marc_source_field), self.class.marc_format_type
    ) if key?(self.class.marc_source_field)
  end
  
end