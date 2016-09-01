# frozen_string_literal: true
# Only works for documents with a #to_marc right now. 
class RecordMailer < ActionMailer::Base
  def email_record(documents, details, url_gen_params)
        
    title = begin
              documents.first.to_semantic_values[:title]
            rescue
              I18n.t('blacklight.email.text.default_title')
            end
    subject = I18n.t('blacklight.email.text.subject', :count => documents.length, :title => title )

    @documents      = documents
    @message        = details[:message]
    @url_gen_params = url_gen_params

    mail(:to => details[:to],  :subject => subject)
  end
  
  def sms_record(documents, details, url_gen_params)
    @documents      = documents
    @url_gen_params = url_gen_params
    mail(:to => details[:to], :subject => "")
  end
end
