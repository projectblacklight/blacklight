# frozen_string_literal: true

module Blacklight
  module Document
    # Render the 'more like this' results from the response
    class GroupComponent < ::ViewComponent::Base
      with_collection_parameter :group

      # @param [Blacklight::Document] document
      def initialize(group:, group_limit: -1)
        @group = group
        @group_limit = group_limit
      end

      def grouped_documents
        @view_context.render_document_index @group.docs
      end

      # Get path to a search within a grouped result set
      #
      # @param [Blacklight::Solr::Response::Group] group
      # @return [Hash]
      def add_group_facet_params_and_redirect(group)
        helpers.search_action_path(
          helpers.search_state.add_facet_params_and_redirect(group.field, group.key)
        )
      end
    end
  end
end
