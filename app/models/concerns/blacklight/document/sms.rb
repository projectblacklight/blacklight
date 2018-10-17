# frozen_string_literal: true
# This module provides the body of an email export based on the document's semantic values
module Blacklight::Document::Sms
  # Return a text string that will be the body of the email
  def to_sms_text(config = nil)
    body = []

    if config
      body = config.sms_fields.map do |name, field|
        values = [self[name]].flatten
        "#{field.label} #{values.first}" if self[name].present?
      end
    end

    # Use to_semantic_values for backwards compatibility
    if body.empty?
      semantics = to_semantic_values
      body << I18n.t('blacklight.sms.text.title', value: semantics[:title].first) if semantics[:title].present?
      body << I18n.t('blacklight.sms.text.author', value: semantics[:author].first) if semantics[:author].present?
    end

    return body.join unless body.empty?
  end
end
