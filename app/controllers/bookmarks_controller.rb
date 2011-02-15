class BookmarksController < ApplicationController
  
  
  before_filter :verify_user
  
  def update
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
  
  def destroy
    if current_user.bookmarks.delete(Bookmark.find(params[:id]))
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
