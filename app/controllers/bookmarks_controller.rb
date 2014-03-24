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

  before_filter :verify_user, :except => :export

  def index
    @bookmarks = current_or_guest_user.bookmarks
    bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }
  
    @response, @document_list = get_solr_response_for_document_ids(bookmark_ids)

    respond_to do |format|
      format.html { }
      format.endnote do 
        # Just concatenate individual endnote exports with blank lines. Not
        # every record can be exported as endnote -- only include those that
        # can.
        render :text => @document_list.collect {|d| d.export_as(:endnote) if d.export_formats.keys.include? :endnote}.join("\n"), :layout => false
      end
    end
  end

  # Much like #index, but does NOT require authentication, instead
  # gets an _encrypted and signed_ user_id in params, and it delivers
  # that users bookmarks, in some export format.
  #
  # Used for third party services requiring callback urls, such as refworks,
  # that need to export a certain users bookmarks without being auth'd as
  # that user.
  def export
    user_id = decrypt_user_id params[:encrypted_user_id]

    @bookmarks = User.find(user_id).bookmarks
    bookmark_ids = @bookmarks.collect { |b| b.document_id.to_s }

    @response, @document_list = get_solr_response_for_field_values(SolrDocument.unique_key, bookmark_ids)

    respond_to do |format|
      format.refworks_marc_txt do        
        # Just concatenate individual refworks_marc_txt exports with blank lines. Not
        # every record can be exported as refworks_marc_txt -- only include those that
        # can.
        render :text => @document_list.collect {|d| d.export_as(:refworks_marc_txt) if d.export_formats.keys.include? :refworks_marc_txt}.join("\n"), :layout => false
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
    flash[:notice] = I18n.t('blacklight.bookmarks.need_login') and raise Blacklight::Exceptions::AccessDenied  unless current_or_guest_user
  end

  def start_new_search_session?
    action_name == "index"
  end

  # Used for #export action, with encrypted user_id.
  def decrypt_user_id(encrypted_user_id)
    encrypter = ActiveSupport::MessageEncryptor.new( bookmarks_export_secret_token )
    return encrypter.decrypt_and_verify(encrypted_user_id)
  end

  # Used for #export action with encrypted user_id, available
  # as a helper method for views.
  def encrypt_user_id(user_id)
    encrypter = ActiveSupport::MessageEncryptor.new( bookmarks_export_secret_token )
    return encrypter.encrypt_and_sign(user_id)
  end
  helper_method :encrypt_user_id

  # Secret token used for encrypting user_id in export action?
  # Use our special config blacklight_export_secret_token if defined (recommended for security),
  # otherwise the app's config.secret_key_base if defined (Rails4) otherwise
  # the app's config.secret_key_token if defined (Rails3) otherwise raise.
  def bookmarks_export_secret_token
    if Rails.application.config.respond_to? :blacklight_export_secret_token
      return Rails.application.config.blacklight_export_secret_token
    else      
      # Dynamically set a temporary one. Definitely a bad way to do it,
      # confusing and prob not thread-safe, but probably better than
      # raising an error in old apps that upgraded without setting the
      # export secret token.
      Deprecation.warn(self.class, "You didn't set config.blacklight_export_secret_token. First randomly generate a secret value:\n    $ rake secret\nThen take that value and put it in config/initializers/blacklight_secret_token.rb:\n    Rails.application.config.secret_key_base = $secret\n")
      Rails.application.config.blacklight_export_secret_token = SecureRandom.hex(64)
      return Rails.application.config.blacklight_export_secret_token
    end
  end

end
