class SavedSearchesController < ApplicationController
  def index
    @searches = Search.find_all_by_user_id(session[:user_id])
  end
  
  def save
    unless session[:user_id]
      flash[:error] = "Please log in to save searches."
      redirect_to :back and return
    end
    
    if Search.update(params[:id], :user_id => session[:user_id])
      flash[:notice] = "Successfully saved your search."
    else
      flash[:error] = "The was a problem saving your search."
    end
    redirect_to :back
  end

  # Only dereferences the user rather than removing the item in case it
  # is in the session[:history]
  def destroy
    if Search.update(params[:id].to_i, :user_id => nil)
      flash[:notice] = "Successfully removed that saved search."
    else
      flash[:error] = "Couldn't remove that saved search."
    end
    redirect_to :back
  end
  
  # Only dereferences the user rather than removing the items in case they
  # are in the session[:history]
  def clear
    redirect_to :back and return unless session[:user_id]
    
    if Search.update_all("user_id = NULL", "user_id = #{session[:user_id]}")
      flash[:notice] = "Cleared your saved searches."
    else
      flash[:error] = "There was a problem clearing your search history."
    end
    redirect_to :action => "index"
  end
  
end
