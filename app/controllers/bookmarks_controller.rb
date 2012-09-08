# -*- encoding : utf-8 -*-
# note that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action. 
class BookmarksController < ApplicationController

  before_filter :require_user_authentication_provider
  before_filter :verify_user
  
  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as PUT is supposed to be. 
  # you can also send a bookmark[title] param, which will be used for simplest case
  # or fall through display of Bookmark in list. 
  def update
    bookmark = current_user.existing_bookmark_for(params[:id])
    if bookmark
      #update existing one with new values if present
      bookmark.attributes = params[:bookmark] if params[:bookmark]
    else
      # create new one with values and document_id
      bookmark = current_user.bookmarks.build(params[:bookmark].merge(:document_id => params[:id]))      
    end
    
    success = bookmark.save
    
    unless request.xhr?
      if success
        flash[:notice] = I18n.t('blacklight.bookmarks.add.success')
      else
        flash[:error] = I18n.t('blacklight.bookmarks.add.failure') 
      end
      redirect_to :back
    else
      #ajaxy request doesn't need a redirect and shouldn't have flash set
      render :text => "", :status => (success ? "200" : "500" )
    end    
  end

  def index
    @bookmarks = current_user.bookmarks.page(params[:page])
  end

  # For adding a single bookmark, suggest use PUT/#update to 
  # /bookmarks/$docuemnt_id instead.
  # But this method, accessed via POST to /bookmarks, can be used for
  # creating multiple bookmarks at once, by posting with keys
  # such as bookmarks[n][document_id], bookmarks[n][title]. 
  # It can also be used for creating a single bookmark by including keys
  # bookmark[title] and bookmark[document_id], but in that case #update
  # is simpler. 
  def create
    @bookmarks = params[:bookmarks] || []
    @bookmarks << params[:bookmark] if params[:bookmark]
    
    success = true
    @bookmarks.each do |key, bookmark|
      success = false unless current_user.bookmarks.create(bookmark)
    end
    if @bookmarks.length > 0 && success
      flash[:notice] = I18n.t('blacklight.bookmarks.add.success', :count => @bookmarks.length)
    elsif @bookmarks.length > 0
      flash[:error] = I18n.t('blacklight.bookmarks.add.failure', :count => @bookmarks.length)
    end
    
    redirect_to :back
  end
  
  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be. 
  def destroy
    bookmark = current_user.existing_bookmark_for(params[:id])
    
    success = (!bookmark) || current_user.bookmarks.delete(bookmark)
    
    unless request.xhr?
      if success
        flash[:notice] =  I18n.t('blacklight.bookmarks.remove.success')
      else
        flash[:error] = I18n.t('blacklight.bookmarks.remove.failure')
      end 
      redirect_to :back
    else
      # ajaxy request needs no redirect and should not have flash set
      render :text => "", :status => (success ? "200" : "500")
    end        
  end
  
  def clear    
    if current_user.bookmarks.clear
      flash[:notice] = I18n.t('blacklight.bookmarks.clear.success') 
    else
      flash[:error] = I18n.t('blacklight.bookmarks.clear.failure') 
    end
    redirect_to :action => "index"
  end
  
  protected
  def verify_user
    flash[:notice] = I18n.t('blacklight.bookmarks.need_login') and raise Blacklight::Exceptions::AccessDenied  unless current_user
  end
end
