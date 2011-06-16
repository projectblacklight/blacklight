# -*- encoding : utf-8 -*-
# This module provides the body of an email export based on the document's semantic values
module Blacklight::Solr::Document::Sms

  # Return a text string that will be the body of the email
  def to_sms_text
    semantics = self.to_semantic_values
    body = ""
    body << semantics[:title].first unless semantics[:title].blank?
    body << " by #{semantics[:author].first}" unless semantics[:author].blank?
    return body unless body.blank?
  end

end
