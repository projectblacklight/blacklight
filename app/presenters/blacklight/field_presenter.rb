module Blacklight
  # Renders a field and handles link_to_search or helper_method if supplied
  class FieldPresenter
    def initialize(controller, document, field, field_config, options)
      @controller = controller
      @document = document
      @field = field
      @field_config = field_config
      @options = options
    end

    attr_reader :controller, :document, :field, :field_config, :options
    
    def render
      # TODO move the itemprop stuff here
      case
        when (field_config and field_config.helper_method)
          render_helper
        when (field_config and field_config.link_to_search)
          link_to_search
        else
          ValueRenderer.new(retrieve_values, field_config).render
      end
    end

    private

      def render_helper
        controller.send(field_config.helper_method,
                        options.merge(document: document,
                                      field: field,
                                      config: field_config,
                                      value: retrieve_values))
      end

      # This allows the link to wrap an itemprop
      def link_to_search
        return unless field
        link_field = if field_config.link_to_search === true
                       field_config.key
                     else
                       field_config.link_to_search
                     end

        links = retrieve_values.map do |v|
                  controller.link_to ValueRenderer.new([v], field_config).render,
                                     controller.search_action_path(controller.search_state.reset.add_facet_params(link_field, v))
                end
        links.to_sentence().html_safe
      end

      def retrieve_values
        FieldRetriever.new(document, field, field_config).fetch
      end

  end
end
