module Blacklight
  module Rendering
    class HelperMethod < AbstractStep
      def render
        if config.helper_method
          render_helper # short circut the rest of the steps
        else  
          next_step(values)
        end
      end

      private

        def render_helper
          context.send(config.helper_method,
                       options.merge(document: document,
                                     field: config.field,
                                     config: config,
                                     value: values))
        end
    end
  end
end
