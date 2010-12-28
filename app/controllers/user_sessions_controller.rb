class UserSessionsController < ApplicationController

  ##
  # The login form.
  #
  def new
    @user_session = UserSession.new
    @referer = post_auth_redirect_url
  end

  ##
  # The login action. If the login is successful, the user is re-directed to 
  # the referring page, which should persisted as an HTTP parameter.
  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Welcome #{@user_session.login}!"
      redirect_to post_auth_redirect_url
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
    redirect_to post_auth_redirect_url
  end

  private 
  ##
  # Returns a local URL path component to redirect to after login. 
  # Will be taken from referer query param or referer HTTP header, in that
  # order, but only used if allowable non-blacklisted internal URL, otherwise
  # root_path is used.    
  #
  # `redirect_path` performs some basic checks to ensure the URL is internal
  #  and will not cause redirect loops.
  def post_auth_redirect_url
    referer = params[:referer] || request.referer
    
    if referer && (referer =~ %r|^https?://#{request.host}#{root_path}| ||
        referer =~ %r|^https?://#{request.host}:#{request.port}#{root_path}|)
      #self-referencing absolute url, make it relative
      referer.sub!(%r|^https?://#{request.host}(:#{request.port})?|, '')
    elsif referer && referer =~ %r|^(\w+:)?//|
      Rails.logger.debug("#post_auth_redirect_url will NOT use third party url for post login redirect: #{referer}")
      referer = nil
    end
    
    if referer && referer_blacklist.any? {|blacklisted| referer.starts_with?(blacklisted)  }
      Rails.logger.debug("#post_auth_redirect_url will NOT use a blacklisted url for post login redirect: #{referer}")
      referer = nil
    elsif referer && referer[0,1] != '/'
      Rails.logger.debug("#post_auth_redirect_url will NOT use partial path for post login redirect: #{referer}")
      referer = nil
    end
      
    return referer || root_path      
  end

  ##
  # Returns a list of urls that should /never/ be the redirect target for
  # post_auth_redirect_url. 
  def referer_blacklist
    [login_path, logout_path]
  end
end
