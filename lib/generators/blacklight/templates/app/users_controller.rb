class UsersController < ApplicationController
  before_filter :verify_user, :only => :show # can't show without a logged in user
  
  def show
  end
  
  def new
    @user ||= User.new(params[:user])
  end
  
  def create
    @user ||= User.new(params[:user])
    if @user.save
      flash[:notice] = "Welcome #{@user.login}"
      redirect_to user_path
    else
      render :action => "new"
    end    
  end
        
  protected
  def verify_user
    flash[:notice] = "Please log in to view your profile." and raise Blacklight::Exceptions::AccessDenied  unless current_user
  end
  
end