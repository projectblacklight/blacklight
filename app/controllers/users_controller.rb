class UsersController < ApplicationController
  
  # see vendor/plugins/resource_controller
  resource_controller :singleton
  
  create.flash { "Welcome #{@user.login}!"}
  
  protected
  def object
    @object ||= current_user
  end
  
end