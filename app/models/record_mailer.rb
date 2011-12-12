# -*- encoding : utf-8 -*-
# Only works for documents with a #to_marc right now. 
class RecordMailer < ActionMailer::Base
  
  def email_record(documents, details, from_host, url_gen_params)
    #raise ArgumentError.new("RecordMailer#email_record only works with documents with a #to_marc") unless document.respond_to?(:to_marc)
        
    if documents.size == 1
      subject = "Item Record: #{documents.first.to_semantic_values[:title] rescue 'N/A'}"
    else
      subject = "Item records"
    end

    @documents      = documents
    @message        = details[:message]
    @url_gen_params = url_gen_params

    mail(:to => details[:to],  :from => "no-reply@" << from_host, :subject => subject)
  end
  
  def sms_record(documents, details, from_host, url_gen_params)
    if sms_mapping[details[:carrier]]
      to = "#{details[:to]}@#{sms_mapping[details[:carrier]]}"
    end
    @documents      = documents
    @host           = from_host
    @url_gen_params = url_gen_params
    mail(:to => to, :from => "no-reply@" << from_host, :subject => "")
  end

  protected
  
  def sms_mapping
    {'virgin' => 'vmobl.com',
    'att' => 'txt.att.net',
    'verizon' => 'vtext.com',
    'nextel' => 'messaging.nextel.com',
    'sprint' => 'messaging.sprintpcs.com',
    'tmobile' => 'tmomail.net',
    'alltel' => 'message.alltel.com',
    'cricket' => 'mms.mycricket.com'}
  end
end
