# -*- encoding : utf-8 -*-
class FeedbackController < ApplicationController
  
  # http://expressica.com/simple_captcha/
  # include SimpleCaptcha::ControllerHelpers
  
  # show the feedback form
  def show
    @errors=[]
    if request.post?
      if validate
        Notifier.feedback(params)
        redirect_to feedback_complete_path
      end
    end
  end
  
  protected
  
  # validates the incoming params
  # returns either an empty array or an array with error messages
  def validate
    unless params[:name] =~ /\w+/
      @errors << I18n.t('blacklight.feedback.valid_name') 
    end
    unless params[:email] =~ /\w+@\w+\.\w+/
      @errors << I18n.t('blacklight.feedback.valid_email')
    end
    unless params[:message] =~ /\w+/
      @errors << I18n.t('blacklight.feedback.need_message')
    end
    #unless simple_captcha_valid?
    #  @errors << 'Captcha did not match'
    #end
    @errors.empty?
  end
  
end
