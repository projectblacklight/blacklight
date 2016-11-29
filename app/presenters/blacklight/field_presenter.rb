module Blacklight
  # Renders a field and handles link_to_facet or helper_method if supplied
  class FieldPresenter
    def initialize(controller, document, field_config, options)
      @controller = controller
      @document = document
      @field_config = field_config
      @options = options
    end

    attr_reader :controller, :document, :field_config, :options

    def render
      if options[:value]
        # This prevents helper methods from drawing.
        config = Configuration::NullField.new(field_config.to_h.except(:helper_method))
        values = Array.wrap(options[:value])
      else
        config = field_config
        values = retrieve_values
      end
      Rendering::Pipeline.render(values, config, document, controller, options)
    end

    private

      def retrieve_values
        FieldRetriever.new(document, field_config).fetch
      end
  end
end
