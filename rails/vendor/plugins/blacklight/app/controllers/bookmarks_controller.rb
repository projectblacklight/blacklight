class BookmarksController < ApplicationController
  
  # see vendor/plugins/resource_controller/
  resource_controller
  belongs_to :user
  
   # acts_as_taggable_on_steroids plugin
  helper TagsHelper
  
  # overrides the ResourceController collection method
  # see vendor/plugins/resource_controller/
  def collection
    assocations = nil
    conditions = parent? ? ['user_id=?', parent_object.id] : nil
    if params[:a]=='find' and ! params[:q].blank?
      q = "%#{params[:q]}%"
      conditions.first << ' AND (tags.name LIKE ? OR title LIKE ? OR notes LIKE ?)'
      conditions += [q, q, q]
      assocations = [:tags]
    end
    Bookmark.paginate_by_tag(params[:tag], :per_page=>8, :page=>params[:page], :order=>'bookmarks.id ASC', :conditions=>conditions, :include=>assocations)
  end
  
end