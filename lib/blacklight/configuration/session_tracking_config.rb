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

    def default_applied_params_component(storage)
      case storage
      when false
        nil
      when 'client'
        Blacklight::SearchContext::ClientAppliedParamsComponent
      else
        Blacklight::SearchContext::ServerAppliedParamsComponent
      end
    end

    def default_item_pagination_component(storage)
      case storage
      when false
        nil
      when 'client'
        Blacklight::SearchContext::ClientItemPaginationComponent
      else
        Blacklight::SearchContextComponent
      end
    end
  end
end
