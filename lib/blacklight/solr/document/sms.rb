# This module provides the body of an email export based on the document's semantic values
module Blacklight::Solr::Document::Sms
  def self.extended(document)
    document.will_export_as(:xmx_text, "text")
  end

  # Return a text string that will be the body of the email
  def export_as_sms_text
    semantics = self.to_semantic_values
    body = [semantics[:title].first, semantics[:author].first].join(" by ")
    return body unless body.blank?
  end

end
