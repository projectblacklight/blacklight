# Only works for documents with a #to_marc right now. 
class RecordMailer < ActionMailer::Base

  
  def email_record(document, details, from_host, host)
    raise ArgumentError.new("RecordMailer#email_record only works with documents with a #to_marc") unless document.respond_to?(:to_marc)
    
    recipients details[:to]
    subject "Item Record: #{document.to_marc['245']['a'] rescue 'N/A'}"
    from "no-reply@" << from_host
    body :document => document, :host => host, :message => details[:message]
  end
  
  def sms_record(document, details, from_host, host)
    if sms_mapping[details[:carrier]]
      to = "#{details[:to]}@#{sms_mapping[details[:carrier]]}"
    end
    recipients to
    from "no-reply@" << from_host
    body :document => document, :host => host
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