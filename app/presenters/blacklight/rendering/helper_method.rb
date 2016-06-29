module Blacklight
  module Rendering
    class HelperMethod < AbstractStep
      def render
        return next_step(values) unless config.helper_method
        return render_helper # short circut the rest of the steps
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



