# -*- encoding : utf-8 -*-
class SavedSearchesController < ApplicationController
  include Blacklight::Configurable

  copy_blacklight_config_from(CatalogController)
  before_filter :require_user_authentication_provider
  before_filter :verify_user 
  
  def index
    @searches = current_user.searches
  end
  
  def save    
    current_user.searches << searches_from_history.find(params[:id])
    if current_user.save
      flash[:notice] = I18n.t('blacklight.saved_searches.add.success')
    else
      flash[:error] = I18n.t('blacklight.saved_searches.add.failure')
    end
    redirect_to :back
  end

  # Only dereferences the user rather than removing the item in case it
  # is in the session[:history]
  def forget
    if search = current_user.searches.find(params[:id])
      search.user_id = nil
      search.save

      flash[:notice] =I18n.t('blacklight.saved_searches.remove.success')
    else
      flash[:error] = I18n.t('blacklight.saved_searches.remove.failure')
    end
    redirect_to :back
  end
  
  # Only dereferences the user rather than removing the items in case they
  # are in the session[:history]
  def clear    
    if current_user.searches.update_all("user_id = NULL")
      flash[:notice] = I18n.t('blacklight.saved_searches.clear.success')
    else
      flash[:error] = I18n.t('blacklight.saved_searches.clear.failure') 
    end
    redirect_to :action => "index"
  end


  protected
  def verify_user
    flash[:notice] = I18n.t('blacklight.saved_searches.need_login') and raise Blacklight::Exceptions::AccessDenied unless current_user
  end
end
