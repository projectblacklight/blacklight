# frozen_string_literal: true

# NOTE: that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action.
module Blacklight::Bookmarks
  extend ActiveSupport::Concern

  included do
    ##
    # Give Bookmarks access to the CatalogController configuration
    include Blacklight::Configurable
    include Blacklight::TokenBasedUser

    copy_blacklight_config_from(CatalogController)

    before_action :verify_user

    blacklight_config.track_search_session.storage = false
    blacklight_config.http_method = Blacklight::Engine.config.blacklight.bookmarks_http_method
    blacklight_config.add_results_collection_tool(:clear_bookmarks_widget)

    blacklight_config.show.document_actions[:bookmark].if = false if blacklight_config.show.document_actions[:bookmark]
    blacklight_config.show.document_actions[:sms].if = false if blacklight_config.show.document_actions[:sms]
    blacklight_config.search_builder_class = Blacklight::BookmarksSearchBuilder
  end

  def action_documents
    bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = bookmarks.collect { |b| b.document_id.to_s }
    search_service.fetch(bookmark_ids, rows: bookmark_ids.count)
  end

  def action_success_redirect_path
    bookmarks_path
  end

  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url(*)
    search_catalog_url(*)
  end

  # @return [Hash] a hash of context information to pass through to the search service
  def search_service_context
    { bookmarks: @bookmarks }
  end

  def index
    @bookmarks = token_or_current_or_guest_user.bookmarks
    @response = search_service.search_results

    respond_to do |format|
      format.html {}
      format.rss  { render layout: false }
      format.atom { render layout: false }

      additional_response_formats(format)
      document_export_formats(format)
    end
  end

  def update
    create
  end

  # For adding a single bookmark, suggest use PUT to /bookmarks/:document_id instead (triggering the #update method).
  # This method, accessed via POST to /bookmarks, can be used for creating multiple bookmarks at once, by posting
  # with keys such as bookmarks[n][document_id], bookmarks[n][title].
  # It can also be used for creating a single bookmark by including keys
  # bookmark[title] and bookmark[document_id], but in that case #update
  # is simpler.
  def create
    @bookmarks = if params[:bookmarks]
                   permit_bookmarks[:bookmarks]
                 else
                   [{ document_id: params[:id], document_type: blacklight_config.document_model.to_s }]
                 end

    current_or_guest_user.save! unless current_or_guest_user.persisted?

    bookmarks_to_add = @bookmarks.reject { |bookmark| current_or_guest_user.bookmarks.where(bookmark).exists? }
    success = ActiveRecord::Base.transaction do
      current_or_guest_user.bookmarks.create!(bookmarks_to_add)
    rescue ActiveRecord::RecordInvalid
      false
    end

    create_response(success)
  end

  # Override the create_response method to handle the response appropriately.
  def create_response(success)
    if request.xhr?
      success ? render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count } }) : render(json: current_or_guest_user.errors.full_messages, status: :internal_server_error)
    else
      if @bookmarks.any? && success
        flash[:notice] = I18n.t('blacklight.bookmarks.add.success', count: @bookmarks.length)
      elsif @bookmarks.any?
        flash[:error] = I18n.t('blacklight.bookmarks.add.failure', count: @bookmarks.length)
      end

      redirect_back fallback_location: bookmarks_path
    end
  end

  # Beware, :id is the Solr document_id, not the actual Bookmark id.
  # idempotent, as DELETE is supposed to be.
  def destroy
    @bookmarks =
      if params[:bookmarks]
        permit_bookmarks[:bookmarks]
      else
        [{ document_id: params[:id], document_type: blacklight_config.document_model.to_s }]
      end

    success = @bookmarks.all? do |bookmark|
      bookmark = current_or_guest_user.bookmarks.find_by(bookmark)
      bookmark&.delete && bookmark.destroyed?
    end

    destroy_response(success)
  end

  # Override the destroy_response method to handle the response appropriately.
  def destroy_response(success)
    if success
      if request.xhr?
        render(json: { bookmarks: { count: current_or_guest_user.bookmarks.count } })
      else
        redirect_back fallback_location: bookmarks_path, notice: I18n.t('blacklight.bookmarks.remove.success')
      end
    elsif request.xhr?
      head :internal_server_error # ajaxy request needs no redirect and should not have flash set
    else
      redirect_back fallback_location: bookmarks_path, flash: { error: I18n.t('blacklight.bookmarks.remove.failure') }
    end
  end

  def clear
    if current_or_guest_user.bookmarks.clear
      flash[:notice] = I18n.t('blacklight.bookmarks.clear.success')
    else
      flash[:error] = I18n.t('blacklight.bookmarks.clear.failure')
    end
    redirect_to action: "index"
  end

  private

  def verify_user
    unless current_or_guest_user || (action == "index" && token_or_current_or_guest_user)
      flash[:notice] = I18n.t('blacklight.bookmarks.need_login')
      raise Blacklight::Exceptions::AccessDenied
    end
  end

  def start_new_search_session?
    action_name == "index"
  end

  def permit_bookmarks
    params.permit(bookmarks: [:document_id, :document_type])
  end
end
