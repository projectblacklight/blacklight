# Only works for documents with a #to_marc right now. 
class RecordMailer < ActionMailer::Base

  
  def email_record(documents, details, from_host, url_gen_params)
    #raise ArgumentError.new("RecordMailer#email_record only works with documents with a #to_marc") unless document.respond_to?(:to_marc)
    
    recipients details[:to]
    if documents.size == 1
      subject "Item Record: #{documents.first.to_marc['245']['a'] rescue 'N/A'}"
    else
      subject "Item records"
    end
    from "no-reply@" << from_host
    body :documents => documents, :url_gen_params => url_gen_params, :message => details[:message]
  end
  
  def sms_record(documents, details, from_host, url_gen_params)
    if sms_mapping[details[:carrier]]
      to = "#{details[:to]}@#{sms_mapping[details[:carrier]]}"
    end
    recipients to
    from "no-reply@" << from_host
    body :documents => documents, :url_gen_params => url_gen_params
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