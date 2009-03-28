class UsersController < ApplicationController
  
  # see vendor/plugins/resource_controller
  resource_controller
  
  create.after do
    # find a way to combine this and the sessions controller login logic
    self.current_user = object
    flash[:notice] = "Welcome #{object.login}!"
  end
  
end