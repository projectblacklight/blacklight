# note that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action. 
class BookmarksController < ApplicationController
  
  
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
    
    if bookmark.save
      flash[:notice] = "Successfully added bookmark."
    else
      flash[:error] = "Could not save bookmark."
    end

    redirect_to :back  
  end

  def index
    @bookmarks = current_user.bookmarks.paginate :page => params[:page]
  end

  def create
    success = true
    @bookmarks = params[:bookmarks]
    if @bookmarks.nil?
      sucess = current_user.bookmarks.create(params[:bookmark])
    else
      @bookmarks.each do |key, bookmark|
        success = false unless current_user.bookmarks.create(bookmark)
      end
    end
    if success
      if @bookmarks.nil? || @bookmarks.size == 1
        flash[:notice] = "Successfully added bookmark."
      else
        flash[:notice] = "Successfully added bookmarks."
      end
    else
      flash[:error] = "There was a problem adding that bookmark."      
    end
    redirect_to :back
  end
  
  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be. 
  def destroy
    bookmark = current_user.existing_bookmark_for(params[:id])
    
    if bookmark && current_user.bookmarks.delete(bookmark)
      flash[:notice] = "Successfully removed bookmark."
    else
      flash[:error] = "Sorry, there was a problem removing the bookmark."
    end
    
    redirect_to :back
  end
  
  def clear    
    if current_user.bookmarks.clear
      flash[:notice] = "Cleared your bookmarks."
    else
      flash[:error] = "There was a problem clearing your bookmarks."
    end
    redirect_to :action => "index"
  end
  
  protected
  def verify_user
    flash[:notice] = "Please log in to manage and view your bookmarks." and raise Blacklight::Exceptions::AccessDenied  unless current_user
  end
end
