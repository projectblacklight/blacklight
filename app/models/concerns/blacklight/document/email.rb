# frozen_string_literal: true
# This module provides the body of an email export based on the document's semantic values
module Blacklight::Document::Email
  # Return a text string that will be the body of the email
  def to_email_text(config = nil)
    body = []

    if config
      body = config.email_fields.map do |name, field|
        values = [self[name]].flatten
        "#{field.label} #{values.join(' ')}" if self[name].present?
      end
    end

    # Use to_semantic_values for backwards compatibility
    if body.empty?
      semantics = to_semantic_values
      body << I18n.t('blacklight.email.text.title', value: semantics[:title].join(" ")) if semantics[:title].present?
      body << I18n.t('blacklight.email.text.author', value: semantics[:author].join(" ")) if semantics[:author].present?
      body << I18n.t('blacklight.email.text.format', value: semantics[:format].join(" ")) if semantics[:format].present?
      body << I18n.t('blacklight.email.text.language', value: semantics[:language].join(" ")) if semantics[:language].present?
    end

    return body.join("\n") unless body.empty?
  end
end
