class SearchHistoryController < ApplicationController
  def index
    @searches = session[:history].blank? ? [] : Search.all(session[:history])
  end
  
  def destroy
    if session[:history].delete_at(params[:id].to_i)
      flash[:notice] = "Successfully removed that search history item."
    else
      flash[:error] = "Couldn't remove that search history item."
    end
    redirect_to :back
  end
  
  def clear
    if session[:history].clear
      flash[:notice] = "Cleared your search history."
    else
      flash[:error] = "There was a problem clearing your search history."
    end
    redirect_to :back
  end
end
