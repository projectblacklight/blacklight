class BookmarksController < ApplicationController
  
  # see vendor/plugins/resource_controller/
  resource_controller
  
   # acts_as_taggable_on_steroids plugin
  helper TagsHelper
  
  before_filter :verify_user
  
  # overrides the ResourceController collection method
  # see vendor/plugins/resource_controller/
  def collection
    user_id = current_user ? current_user.id : nil
    assocations = nil
    conditions = ['user_id = ?', user_id]
    if params[:a] == 'find' && ! params[:q].blank?
      q = "%#{params[:q]}%"
      conditions.first << ' AND (tags.name LIKE ? OR title LIKE ? OR notes LIKE ?)'
      conditions += [q, q, q]
      assocations = [:tags]
    end
    Bookmark.paginate_by_tag(params[:tag], :per_page => 8, :page => params[:page], :order => 'bookmarks.id ASC', :conditions => conditions, :include => assocations)
  end
  
  update.wants.html { redirect_to :back }
  
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
      flash[:notice] = "Successfully removed that bookmark."
    else
      flash[:error] = "Couldn't remove that bookmark."
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
    flash[:error] = "Please log in to manage and view your bookmarks." and redirect_to(login_url(:referer => request.request_uri)) unless current_user
  end
end
