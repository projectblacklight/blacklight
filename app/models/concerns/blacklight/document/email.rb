# frozen_string_literal: true
# This module provides the body of an email export based on the document's semantic values
module Blacklight::Document::Email
  # Return a text string that will be the body of the email
  def to_email_text
    semantics = to_semantic_values
    body = []
    body << I18n.t('blacklight.email.text.title', value: semantics[:title].join(" ")) unless semantics[:title].blank?
    body << I18n.t('blacklight.email.text.author', value: semantics[:author].join(" ")) unless semantics[:author].blank?
    body << I18n.t('blacklight.email.text.format', value: semantics[:format].join(" ")) unless semantics[:format].blank?
    body << I18n.t('blacklight.email.text.language', value: semantics[:language].join(" ")) unless semantics[:language].blank?
    return body.join("\n") unless body.empty?
  end
end
