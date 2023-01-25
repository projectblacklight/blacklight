# frozen_string_literal: true

module Blacklight
  module Document
    # Render a the set of actions for a document. One of the default actions is the bookmark control.
    class ActionsComponent < Blacklight::Component
      renders_many :actions, (lambda do |action:, component: nil, **kwargs|
        component ||= action.component || Blacklight::Document::ActionComponent
        component.new(action: action, document: @document, options: @options, url_opts: @url_opts, link_classes: @link_classes, **kwargs)
      end)

      # @param [Blacklight::Document] document
      # rubocop:disable Metrics/ParameterLists
      def initialize(document: nil, actions: [], options: {}, url_opts: nil, tag: :div, classes: 'index-document-functions', wrapping_tag: nil, wrapping_classes: nil, link_classes: 'nav-link')
        @document = document
        @actions = actions
        @tag = tag
        @classes = classes
        @options = options
        @url_opts = url_opts
        @wrapping_tag = wrapping_tag
        @wrapping_classes = wrapping_classes
        @link_classes = link_classes
      end
      # rubocop:enable Metrics/ParameterLists

      def before_render
        return if actions.present?

        @actions.each do |a|
          with_action(component: a.component, action: a)
        end
      end

      def render?
        actions.present?
      end
    end
  end
end
