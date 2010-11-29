class UsersController < ApplicationController
  before_filter :verify_user, :only => :show # can't show without a logged in user
  
  # see vendor/plugins/resource_controller
  resource_controller :singleton
  
  create.flash { "Welcome #{@user.login}!"}
  
  
  protected
  def object
    @object ||= current_user
  end
  
  protected
  def verify_user
    flash[:error] = "Please log in to view your profile." and raise Blacklight::Exceptions::AccessDenied  unless current_user
  end
  
end