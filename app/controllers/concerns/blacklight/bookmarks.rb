# frozen_string_literal: true
# note that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action.
module Blacklight::Bookmarks
  extend ActiveSupport::Concern

  included do
    ##
    # Give Bookmarks access to the CatalogController configuration
    include Blacklight::Configurable
    include Blacklight::SearchHelper
    include Blacklight::TokenBasedUser

    copy_blacklight_config_from(CatalogController)

    before_action :verify_user

    blacklight_config.http_method = Blacklight::Engine.config.bookmarks_http_method
    blacklight_config.add_results_collection_tool(:clear_bookmarks_widget)

    blacklight_config.show.document_actions[:bookmark].if = false if blacklight_config.show.document_actions[:bookmark]
    blacklight_config.show.document_actions[:sms].if = false if blacklight_config.show.document_actions[:sms]
  end

  def action_documents
    bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = bookmarks.collect { |b| b.document_id.to_s }
    fetch(bookmark_ids)
  end

  def action_success_redirect_path
    bookmarks_path
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url *args
    search_catalog_url(*args)
  end

  def index
    @bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }

    @response, @document_list = fetch(bookmark_ids)

    respond_to do |format|
      format.html { }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        render json: render_search_results_as_json
      end

      additional_response_formats(format)
      document_export_formats(format)
    end
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
    @bookmarks = if params[:bookmarks]
                   params[:bookmarks]
                 else
                   [{ document_id: params[:id], document_type: blacklight_config.document_model.to_s }]
                 end

    current_or_guest_user.save! unless current_or_guest_user.persisted?

    success = @bookmarks.all? do |bookmark|
       current_or_guest_user.bookmarks.where(bookmark).exists? || current_or_guest_user.bookmarks.create(bookmark)
    end

    if request.xhr?
      success ? render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count }}) : render(:text => "", :status => "500")
    else
      if @bookmarks.any? && success
        flash[:notice] = I18n.t('blacklight.bookmarks.add.success', :count => @bookmarks.length)
      elsif @bookmarks.any?
        flash[:error] = I18n.t('blacklight.bookmarks.add.failure', :count => @bookmarks.length)
      end

      if respond_to? :redirect_back
        redirect_back fallback_location: bookmarks_path
      else
        # Deprecated in Rails 5.0
        redirect_to :back
      end
    end
  end

  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be.
  def destroy
    bookmark = current_or_guest_user.bookmarks.find_by(document_id: params[:id], document_type: blacklight_config.document_model.to_s)

    if bookmark && bookmark.delete && bookmark.destroyed?
      if request.xhr?
        render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count }})
      elsif respond_to? :redirect_back
        redirect_back fallback_location: bookmarks_path, notice: I18n.t('blacklight.bookmarks.remove.success')
      else
        # Deprecated in Rails 5.0
        redirect_to :back, notice: I18n.t('blacklight.bookmarks.remove.success')
      end
    else
      if request.xhr?
        # ajaxy request needs no redirect and should not have flash set
        render(:text => "", :status => "500")
      elsif respond_to? :redirect_back
        redirect_back fallback_location: bookmarks_path, flash: { error: I18n.t('blacklight.bookmarks.remove.failure') }
      else
        # Deprecated in Rails 5.0
        redirect_to :back, flash: { error: I18n.t('blacklight.bookmarks.remove.failure') }
      end
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
    unless current_or_guest_user or (action == "index" and token_or_current_or_guest_user)
      flash[:notice] = I18n.t('blacklight.bookmarks.need_login') and raise Blacklight::Exceptions::AccessDenied
    end
  end

  def start_new_search_session?
    action_name == "index"
  end
end
