require 'delegate'

module Blacklight
  module Catalog::DocumentActions
    extend ActiveSupport::Concern


    included do
      class_attribute :inheritable_document_actions
      helper_method :document_actions
    end

    module ClassMethods
      def document_actions
        @document_actions ||= (inheritable_document_actions || Hash.new).deep_dup
      end

      ##
      # @param name [Symbol] the name of the document action and is used to calculate
      #                           partial names, path helpers, and other defaults
      # @param opts [Hash]
      # @option opts [Symbol,Proc] :if render this action if the method identified by the symbol or the proc evaluates to true. 
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol,Proc] :unless render this action unless the method identified by the symbol or the proc evaluates to true
      #                             The proc will receive the action configuration and the document or documents for the action.
      # @option opts [Symbol] :callback If this action accepts POST requests, the name of a method to invoke
      # @option opts [Symbol] :validator If this action accepts POST requests, the name of a method to invoke before the callback to validate the parameters
      # @option opts [String] :partial a partial to use to render this action in the relevant tool bars
      # @option opts [String] :label (for the default tool partial) a label to use for this action
      # @option opts [String] :path (for the default tool partial) a path helper to give a route for this action
      #
      def add_document_action name, opts = {}
        config = Blacklight::Configuration::ToolConfig.new opts
        config.name = name

        if block_given?
          yield config
        end

        document_actions[name] = config

        self.inheritable_document_actions = document_actions

        define_method name do
          @response, @documents = action_documents
          if request.post? and
              opts[:callback] and
              (opts[:validator].blank? || self.send(opts[:validator]))

            self.send(opts[:callback], @documents)

            flash[:success] ||= I18n.t("blacklight.#{name}.success", default: nil)

            respond_to do |format|
              format.html { redirect_to action_success_redirect_path }
              format.js { render "#{name}_success" }
            end
          else
            respond_to do |format|
              format.html
              format.js { render :layout => false }
            end
          end
        end
      end
    end

    def document_actions
      @document_actions ||= self.class.document_actions.deep_dup
    end
  end
end