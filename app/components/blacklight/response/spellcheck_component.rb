# frozen_string_literal: true

module Blacklight
  module Response
    # Render spellcheck results for a search query
    class SpellcheckComponent < ViewComponent::Base
      # @param [Blacklight::Response] response
      # @param [Array<String>] options explicit spellcheck options to render
      def initialize(response:, options: nil)
        @response = response
        @options = options || @response&.spelling&.words
      end

      def link_to_query(query)
        p = @view_context.search_state.to_h.except(:page, :action)
        p[:q] = query
        link_to(query, @view_context.search_action_path(p))
      end

      def render?
        @options.any? && should_show_spellcheck_suggestions?
      end

      private

      ##
      # Determine whether to display spellcheck suggestions
      #
      # @param [Blacklight::Solr::Response] response
      # @return [Boolean]
      def should_show_spellcheck_suggestions?
        # The spelling response field may be missing from non solr repositories.
        @response.total <= @view_context.blacklight_config.spell_max &&
          !@response.spelling.nil? &&
          @response.spelling.words.any?
      end
    end
  end
end
