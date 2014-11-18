module Blacklight
  module Catalog::IndexTools
    extend ActiveSupport::Concern
    included do
      class_attribute :inheritable_tool_partials
      helper_method :index_tool_partials
    end

    def index_tool_partials
      self.class.index_tool_partials
    end

    module ClassMethods
      def index_tool_partials
        @index_tool_partials ||= (inheritable_tool_partials || Hash.new).deep_dup
      end

      ##
      # @param partial [String] the name of the document partial
      # @param opts [Hash]
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true.
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      def add_index_tools_partial name, opts = {}
        config = Blacklight::Configuration::ToolConfig.new opts
        config.name = name

        if block_given?
          yield config
        end

        index_tool_partials[name] = config

        self.inheritable_tool_partials = index_tool_partials
      end
    end
  end
end
