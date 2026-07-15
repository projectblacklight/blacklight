# frozen_string_literal: true

module Blacklight
  module SearchHistory
    extend ActiveSupport::Concern
    include Blacklight::Configurable
    include Blacklight::SearchContext

    included do
      allow_unauthenticated_access raise: false if respond_to?(:allow_unauthenticated_access)

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

      redirect_back_or_to(blacklight.search_history_path)
    end
  end
end
