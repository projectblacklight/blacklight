# frozen_string_literal: true
module Blacklight
  module SavedSearches
    extend ActiveSupport::Concern
    include Blacklight::Configurable

    included do
      copy_blacklight_config_from(CatalogController)
      before_action :require_user_authentication_provider
      before_action :verify_user
    end

    def index
      @searches = current_user.searches
    end

    def save
      current_user.searches << searches_from_history.find(params[:id])
      if current_user.save
        flash[:notice] = I18n.t('blacklight.saved_searches.add.success')
      else
        flash[:error] = I18n.t('blacklight.saved_searches.add.failure')
      end
      if respond_to? :redirect_back
        redirect_back fallback_location: blacklight.saved_searches_path
      else
        # Deprecated in Rails 5.0
        redirect_to :back
      end
    end

    # Only dereferences the user rather than removing the item in case it
    # is in the session[:history]
    def forget
      search = current_user.searches.find(params[:id])

      if search.present?
        search.user_id = nil
        search.save

        flash[:notice] = I18n.t('blacklight.saved_searches.remove.success')
      else
        flash[:error] = I18n.t('blacklight.saved_searches.remove.failure')
      end
      if respond_to? :redirect_back
        redirect_back fallback_location: blacklight.saved_searches_path
      else
        # Deprecated in Rails 5.0
        redirect_to :back
      end
    end

    # Only dereferences the user rather than removing the items in case they
    # are in the session[:history]
    def clear
      if current_user.searches.update_all("user_id = NULL")
        flash[:notice] = I18n.t('blacklight.saved_searches.clear.success')
      else
        flash[:error] = I18n.t('blacklight.saved_searches.clear.failure')
      end
      redirect_to blacklight.saved_searches_url
    end

    protected

      def verify_user
        flash[:notice] = I18n.t('blacklight.saved_searches.need_login') && raise(Blacklight::Exceptions::AccessDenied) unless current_user
      end
  end
end
