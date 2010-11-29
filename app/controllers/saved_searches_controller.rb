class SavedSearchesController < ApplicationController
  before_filter :verify_user 
  
  def index
    @searches = Search.find_all_by_user_id(current_user.id)
  end
  
  def save    
    if Search.update(params[:id], :user_id => current_user.id)
      flash[:notice] = "Successfully saved your search."
    else
      flash[:error] = "The was a problem saving your search."
    end
    redirect_to :back
  end

  # Only dereferences the user rather than removing the item in case it
  # is in the session[:history]
  def destroy
    if current_user.search_ids.include?(params[:id].to_i) && Search.update(params[:id].to_i, :user_id => nil)
      flash[:notice] = "Successfully removed that saved search."
    else
      flash[:error] = "Couldn't remove that saved search."
    end
    redirect_to :back
  end
  
  # Only dereferences the user rather than removing the items in case they
  # are in the session[:history]
  def clear    
    if Search.update_all("user_id = NULL", "user_id = #{current_user.id}")
      flash[:notice] = "Cleared your saved searches."
    else
      flash[:error] = "There was a problem clearing your saved searches."
    end
    redirect_to :action => "index"
  end


  protected
  def verify_user
    flash[:error] = "Please log in to manage and view your saved searches." and redirect_to(login_url(:referer => request.request_uri)) unless current_user
  end
end
