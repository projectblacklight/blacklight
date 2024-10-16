# frozen_string_literal: true

class Blacklight::Configuration
  class SessionTrackingConfig < Blacklight::OpenStructWithHashAccess
    # @!attribute storage
    #   @return [String, FalseClass] 'server': use server-side tracking; 'client': delegate search tracking and prev/next navigation to client
    # @!attribute applied_params_component
    #   @return [Class] component class used to render a facet group
    # @!attribute item_pagination_component
    #   @return [Class] component class used to render the constraints

    def initialize(property_hash = {})
      super({ storage: 'server' }.merge(property_hash))
    end

    def applied_params_component
      super || default_applied_params_component(storage)
    end

    def item_pagination_component
      super || default_item_pagination_component(storage)
    end

    def url_helper
      super || default_url_helper(storage)
    end

    def default_applied_params_component(storage)
      return Blacklight::SearchContext::ServerAppliedParamsComponent if storage == 'server'

      nil
    end

    def default_item_pagination_component(storage)
      return Blacklight::SearchContextComponent if storage == 'server'

      nil
    end

    # extension point for alternative storage types
    def default_url_helper(_storage)
      nil
    end
  end
end
