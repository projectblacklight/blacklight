# frozen_string_literal: true
module Blacklight
  module Suggest
    extend ActiveSupport::Concern

    included do
      include Blacklight::Configurable
      include Blacklight::SearchHelper

      copy_blacklight_config_from(CatalogController)
    end

    def index
      respond_to do |format|
        format.json do
          render json: suggestions_service.suggestions
        end
      end
    end

    def suggestions_service
      Blacklight::SuggestSearch.new(params, repository).suggestions
    end
  end
end
