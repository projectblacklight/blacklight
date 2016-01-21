module Blacklight
  module SearchHistory
    extend ActiveSupport::Concern
    include Blacklight::Configurable

    included do
      copy_blacklight_config_from(CatalogController)
    end

    def index
      @searches = searches_from_history
    end

    # TODO: we may want to remove unsaved (those without user_id) items from
    # the database when removed from history
    def clear
      if session[:history].clear
        flash[:notice] = I18n.t('blacklight.search_history.clear.success')
      else
        flash[:error] = I18n.t('blacklight.search_history.clear.failure')
      end

      if respond_to? :redirect_back
        redirect_back fallback_location: blacklight.search_history_path
      else
        # Deprecated in Rails 5.0
        redirect_to :back
      end
    end
  end
end
