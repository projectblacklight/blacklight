class SessionsController < ApplicationController
  
  # see: vendor/plugins/blacklight/lib/cookies_required.rb
  #extend CookiesRequired
  
  #cookies_required do |options, sessions_controller|
  #  options[:success_redirect_to] = sessions_controller.send(:catalog_index_path)
  #end
  
  def create
    if user = User.authenticate(params[:email], params[:password])
      self.current_user = user
      user.update_attribute(:last_login, Time.now)
      flash[:notice] = "Welcome #{user.login}!"
      redirect_to root_path
    else
      flash.now[:error] =  "Couldn't locate a user with those credentials"
      render :action => :new
    end
  end
  
end