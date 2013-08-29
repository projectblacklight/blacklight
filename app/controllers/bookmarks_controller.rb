# -*- encoding : utf-8 -*-
# note that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action. 
class BookmarksController < CatalogController

  ##
  # Give Bookmarks access to the CatalogController configuration
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  copy_blacklight_config_from(CatalogController)
 
  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url *args
    catalog_index_url *args
  end
  helper_method :search_action_url

  before_filter :verify_user

  def index
    @bookmarks = current_or_guest_user.bookmarks
    bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }
  
    @response, @document_list = get_solr_response_for_field_values(SolrDocument.unique_key, bookmark_ids)
  end

  def update
    create
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
    if params[:bookmarks]
      @bookmarks = params[:bookmarks]
    else
      @bookmarks = [{ :document_id => params[:id] }]
    end

    current_or_guest_user.save! unless current_or_guest_user.persisted?

    success = @bookmarks.all? do |bookmark|
      current_or_guest_user.bookmarks.create(bookmark) unless current_or_guest_user.existing_bookmark_for(bookmark[:document_id])
    end

    if request.xhr?
      success ? head(:no_content) : render(:text => "", :status => "500")
    else
      if @bookmarks.length > 0 && success
        flash[:notice] = I18n.t('blacklight.bookmarks.add.success', :count => @bookmarks.length)
      elsif @bookmarks.length > 0
        flash[:error] = I18n.t('blacklight.bookmarks.add.failure', :count => @bookmarks.length)
      end

      redirect_to :back
    end
  end
  
  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be. 
  def destroy
    bookmark = current_or_guest_user.existing_bookmark_for(params[:id])
    
    success = (!bookmark) || current_or_guest_user.bookmarks.delete(bookmark)
    
    unless request.xhr?
      if success
        flash[:notice] =  I18n.t('blacklight.bookmarks.remove.success')
      else
        flash[:error] = I18n.t('blacklight.bookmarks.remove.failure')
      end 
      redirect_to :back
    else
      # ajaxy request needs no redirect and should not have flash set
      success ? head(:no_content) : render(:text => "", :status => "500")
    end        
  end
  
  def clear    
    if current_or_guest_user.bookmarks.clear
      flash[:notice] = I18n.t('blacklight.bookmarks.clear.success') 
    else
      flash[:error] = I18n.t('blacklight.bookmarks.clear.failure') 
    end
    redirect_to :action => "index"
  end
  
  protected
  def verify_user
    flash[:notice] = I18n.t('blacklight.bookmarks.need_login') and raise Blacklight::Exceptions::AccessDenied  unless current_or_guest_user
  end
end
