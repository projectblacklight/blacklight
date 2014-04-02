# -*- encoding : utf-8 -*-
# note that while this is mostly restful routing, the #update and #destroy actions
# take the Solr document ID as the :id, NOT the id of the actual Bookmark action. 
class BookmarksController < CatalogController

  ##
  # Give Bookmarks access to the CatalogController configuration
  include Blacklight::Configurable
  include Blacklight::SolrHelper

  copy_blacklight_config_from(CatalogController)

  rescue_from Blacklight::Exceptions::ExpiredSessionToken do
    head :unauthorized
  end
 
  # Blacklight uses #search_action_url to figure out the right URL for
  # the global search box
  def search_action_url *args
    catalog_index_url *args
  end

  before_filter :verify_user

  def index
    @bookmarks = token_or_current_or_guest_user.bookmarks
    bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }
  
    @response, @document_list = get_solr_response_for_document_ids(bookmark_ids)

    respond_to do |format|
      format.html { }
      format.rss  { render :layout => false }
      format.atom { render :layout => false }
      format.json do
        render json: render_search_results_as_json
      end

      additional_response_formats(format)
      
      format.endnote do 
        render :text => @response.to_endnote, :layout => false
      end

      format.refworks_marc_txt do        
        render :text => @response.to_refworks_marc_txt, :layout => false
      end
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
    if params[:bookmarks]
      @bookmarks = params[:bookmarks]
    else
      @bookmarks = [{ document_id: params[:id], document_type: blacklight_config.solr_document_model.to_s }]
    end

    current_or_guest_user.save! unless current_or_guest_user.persisted?

    success = @bookmarks.all? do |bookmark|
      current_or_guest_user.bookmarks.create(bookmark) unless current_or_guest_user.bookmarks.where(bookmark).exists?
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
    bookmark = current_or_guest_user.bookmarks.where(document_id: params[:id], document_type: blacklight_config.solr_document_model).first

    success = bookmark && bookmark.delete && bookmark.destroyed?

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
    unless current_or_guest_user or (action == "index" and token_or_current_or_guest_user)
      flash[:notice] = I18n.t('blacklight.bookmarks.need_login') and raise Blacklight::Exceptions::AccessDenied
    end
  end

  def start_new_search_session?
    action_name == "index"
  end

  # Used for #export action, with encrypted user_id.
  def decrypt_user_id(encrypted_user_id)
    user_id, timestamp = message_encryptor.decrypt_and_verify(encrypted_user_id)

    if timestamp < 1.hour.ago
      raise Blacklight::Exceptions::ExpiredSessionToken.new
    end

    user_id
  end

  # Used for #export action with encrypted user_id, available
  # as a helper method for views.
  def encrypt_user_id(user_id)
    message_encryptor.encrypt_and_sign([user_id, Time.now])
  end
  helper_method :encrypt_user_id
  
  ##
  # This method provides Rails 3 compatibility to our message encryptor.
  # When we drop support for Rails 3, we can just use the AS::KeyGenerator
  # directly instead of this helper.
  def bookmarks_export_secret_token salt
    OpenSSL::PKCS5.pbkdf2_hmac_sha1(Blacklight.secret_key, salt, 1000, 64)
  end
  
  def message_encryptor
    derived_secret = bookmarks_export_secret_token("bookmarks session key")
    ActiveSupport::MessageEncryptor.new(derived_secret)
  end
  
  def token_or_current_or_guest_user
    token_user || current_or_guest_user
  end
  
  def token_user
    @token_user ||= if params[:encrypted_user_id]
      user_id = decrypt_user_id params[:encrypted_user_id]
      User.find(user_id)
    else
      nil
    end
  end
end
