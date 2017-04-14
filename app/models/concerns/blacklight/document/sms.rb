# frozen_string_literal: true

# This module provides the body of an email export based on the document's semantic values
module Blacklight::Document::Sms
  # Return a text string that will be the body of the email
  def to_sms_text
    semantics = to_semantic_values
    body = []
    body << I18n.t('blacklight.sms.text.title', value: semantics[:title].first) if semantics[:title].present?
    body << I18n.t('blacklight.sms.text.author', value: semantics[:author].first) if semantics[:author].present?
    return body.join unless body.empty?
  end
end
