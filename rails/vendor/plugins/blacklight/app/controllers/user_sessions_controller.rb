class UserSessionsController < ApplicationController
#   before_filter :require_no_user, :only => [:new, :create]
#   before_filter :require_user, :only => :destroy
  
#   def create
#     if user = User.authenticate(params[:email], params[:password])
#       self.current_user = user
#       user.update_attribute(:last_login, Time.now)
#       flash[:notice] = "Welcome #{user.login}!"
#       redirect_to root_path
#     else
#       flash.now[:error] =  "Couldn't locate a user with those credentials"
#       render :action => :new
#     end
#   end
#   
#   def destroy
#     session[:user_id] = nil
#     flash[:notice] = "You have successfully logged out."
#     redirect_to root_path
#   end
  
  def new
    @user_session = UserSession.new
  end

  def create
    @user_session = UserSession.new(params[:user_session])
    if @user_session.save
      flash[:notice] = "Welcome #{@user_session.login}!"
      redirect_to root_path
    else
      flash.now[:error] =  "Couldn't locate a user with those credentials"
      render :action => :new
    end
  end

  def destroy
    current_user_session.destroy
    flash[:notice] = "You have successfully logged out."
    redirect_to root_path
  end
end
