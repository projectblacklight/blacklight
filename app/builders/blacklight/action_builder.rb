# frozen_string_literal: true

module Blacklight
  # Dynamically creates methods on the given controller (typically CatalogController)
  # for handling configured show tools
  class ActionBuilder
    # @param [Object] klass
    # @param [String] name
    # @param [Hash] opts
    # @option opts [Symbol] callback
    # @option opts [Symbol] validator
    # @option opts [Boolean] define_method
    def initialize(klass, name, opts)
      @klass = klass
      @name = name
      @opts = opts
    end

    attr_reader :klass, :name, :opts

    # Define a simple action handler for the tool as long as the method
    # doesn't already exist or the `:define_method` option is not `false`
    def build
      return if skip?

      callback = opts.fetch(:callback, nil).inspect
      validator = opts.fetch(:validator, nil).inspect
      klass.class_eval <<EORUBY, __FILE__, __LINE__ + 1
          def #{name}
            @documents = action_documents

            if request.post? && #{callback}
              if #{validator}.blank? || send(#{validator})

                send(#{callback}, @documents)

                flash.now[:success] ||= I18n.t("blacklight.#{name}.success", default: nil)

                respond_to do |format|
                  format.html do
                    return render "#{name}_success", layout: false if request.xhr?
                    redirect_to action_success_redirect_path
                  end
                end
              else
                # Not valid
                respond_to do |format|
                  format.html do
                    return render layout: false, status: :unprocessable_entity if request.xhr?
                    # Otherwise draw the full page
                  end
                end
              end
            else
              respond_to do |format|
                format.html do
                  return render layout: false if request.xhr?
                  # Otherwise draw the full page
                end
              end
            end
          end
EORUBY
    end

    private

    def skip?
      klass.method_defined?(name) || opts[:define_method] == false
    end
  end
end
