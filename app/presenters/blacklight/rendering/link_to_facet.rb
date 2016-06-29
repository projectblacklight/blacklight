module Blacklight
  module Rendering
    class LinkToFacet < AbstractStep
      def render
        # TODO: We should rename the config variable, because it creates a link to a facet.
        return next_step(values) unless config.link_to_search
        next_step(render_link)
      end

      private

        # This allows the link to wrap an itemprop
        def render_link
          values.map { |v| link(link_field, v) }
        end

        def link_field
          return config.key if config.link_to_search === true
          config.link_to_search
        end

        def link(field, v)
          context.link_to v, search_path(field, v)
        end

        def search_path(field, v)
          context.search_action_path(facet_params(field, v))
        end

        def facet_params(field, v)
          context.search_state.reset.add_facet_params(field, v)
        end
    end
  end
end
