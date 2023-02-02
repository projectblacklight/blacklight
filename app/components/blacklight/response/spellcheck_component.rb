# frozen_string_literal: true

module Blacklight
  module Response
    # Render spellcheck results for a search query
    class SpellcheckComponent < Blacklight::Component
      # @param [Blacklight::Response] response
      # @param [Array<String>] options explicit spellcheck options to render
      def initialize(response:, options: nil)
        @response = response
        @options = options
        @options ||= options_from_response(@response)
      end

      def link_to_query(query)
        p = helpers.search_state.to_h.except(:page, :action)
        p[:q] = query
        link_to(query, helpers.search_action_path(p))
      end

      def render?
        Array(@options).any? && show_spellcheck_suggestions?(@response)
      end

      # @!group Search result helpers
      ##
      # Determine whether to display spellcheck suggestions
      #
      # @param [Blacklight::Solr::Response] response
      # @return [Boolean]
      def show_spellcheck_suggestions? response
        # The spelling response field may be missing from non solr repositories.
        response.total <= helpers.blacklight_config.spell_max &&
          !response.spelling.nil? &&
          response.spelling.words.any?
      end

      private

      def options_from_response(response)
        if response&.spelling&.collation
          [response.spelling.collation]
        elsif response&.spelling&.words
          response.spelling.words
        end
      end
    end
  end
end
