class UserSessionsController < ApplicationController

  ##
  # The login form.
  #
  def new
    @user_session = UserSession.new
    @referer = referer_url
  end

  ##
  # The login action. If the login is successful, the user is re-directed to 
  # the referring page, which should persisted as an HTTP parameter.
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Welcome #{@user_session.login}!"
      redirect_to referer_url
    else
      flash.now[:error] =  "Couldn't locate a user with those credentials"
      render :action => :new
    end
  end


  ##
  # The logout action. The user is redirected to the previous page,
  # given as an HTTP parameter /or/ from the referer header.
  def destroy
    current_user_session.destroy rescue nil
    flash[:notice] = "You have successfully logged out."
    session[:logout] = true
    redirect_to referer_url
  end

  private 
  ##
  # Returns a url (or the root path, by default) to the page from which a user
  # began the login/logout process. It examines the referer (sic) HTTP param,
  # as well as the request's referer to determine the correct page. 
  #
  # `redirect_path` performs some basic checks to ensure the URL is internal
  #  and will not cause redirect loops.
  def referer_url
    referer = params[:referer] if params[:referer]
    referer ||= request.referer if request.referer
    referer &&= referer.sub(Regexp.new("^http://#{request.env["HTTP_HOST"]}"), '') if request.env["HTTP_HOST"]

    return referer if referer and referer =~ /^\// and not referer_blacklist.any? { |x| referer =~ Regexp.new("^#{x}") }
    return root_path
  end

  ##
  # Returns a list of urls that should /never/ be the redirect target for
  # referer_url. 
  def referer_blacklist
    [login_path, logout_path]
  end
end
