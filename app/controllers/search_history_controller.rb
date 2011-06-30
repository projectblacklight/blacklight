# -*- encoding : utf-8 -*-
class SearchHistoryController < ApplicationController
  def index
    @searches = searches_from_history
  end
  
  
  #TODO we may want to remove unsaved (those without user_id) items from the database when removed from history
  def clear
    if session[:history].clear
      flash[:notice] = "Cleared your search history."
    else
      flash[:error] = "There was a problem clearing your search history."
    end
    redirect_to :back
  end
end
