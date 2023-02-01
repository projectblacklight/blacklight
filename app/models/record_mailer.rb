# frozen_string_literal: true

# Only works for documents with a #to_marc right now.
class RecordMailer < ApplicationMailer
  helper CatalogHelper
  helper_method :blacklight_config, :blacklight_configuration_context

  def email_record(documents, details, url_gen_params)
    @documents      = documents
    @message        = details[:message]
    @config         = details[:config]
    @url_gen_params = url_gen_params

    title = view_context.document_presenter(documents.first).html_title || I18n.t('blacklight.email.text.default_title')

    subject = I18n.t('blacklight.email.text.subject',
                     count: documents.length,
                     title: Array(title).first)

    mail(to: details[:to], subject: subject)
  end

  def sms_record(documents, details, url_gen_params)
    @documents      = documents
    @config         = details[:config]
    @url_gen_params = url_gen_params

    mail(to: details[:to], subject: "") # rubocop:disable Rails/I18nLocaleTexts
  end

  def blacklight_config
    @config || Blacklight.default_configuration
  end

  ##
  # Context in which to evaluate blacklight configuration conditionals
  def blacklight_configuration_context
    @blacklight_configuration_context ||= Blacklight::Configuration::Context.new(self)
  end
end
