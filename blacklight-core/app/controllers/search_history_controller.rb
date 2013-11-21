# -*- encoding : utf-8 -*-
class SearchHistoryController < ApplicationController
  include Blacklight::Configurable

  copy_blacklight_config_from(CatalogController)

  def index
    @searches = searches_from_history
  end
  
  
  #TODO we may want to remove unsaved (those without user_id) items from the database when removed from history
  def clear
    if session[:history].clear
      flash[:notice] = I18n.t('blacklight.search_history.clear.success')
    else
      flash[:error] = I18n.t('blacklight.search_history.clear.failure') 
    end
    redirect_to :back
  end
end
