class FeedbackController < BlacklightController
  
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
      @errors << 'A valid name is required'
    end
    unless params[:email] =~ /\w+@\w+\.\w+/
      @errors << 'A valid email address is required'
    end
    unless params[:message] =~ /\w+/
      @errors << 'A message is required'
    end
    #unless simple_captcha_valid?
    #  @errors << 'Captcha did not match'
    #end
    @errors.empty?
  end
  
end
