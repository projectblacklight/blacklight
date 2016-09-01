# frozen_string_literal: true
module Blacklight
  # @deprecated
  class DocumentPresenter
    extend Deprecation
    self.deprecation_horizon = 'Blacklight version 7.0.0'

    # @param [SolrDocument] document
    # @param [ActionController::Base] controller scope for linking and generating urls
    # @param [Blacklight::Configuration] configuration
    def initialize(document, controller, configuration = controller.blacklight_config)
      @document = document
      @configuration = configuration
      @controller = controller
    end

    ##
    # Get the value of the document's "title" field, or a placeholder
    # value (if empty)
    #
    # @return [String]
    # @deprecated use ShowPresenter#heading instead
    def document_heading
      show_presenter.heading
    end
    deprecation_deprecate document_heading: "use ShowPresenter#heading instead"

    ##
    # Create <link rel="alternate"> links from a documents dynamically
    # provided export formats. Returns empty string if no links available.
    #
    # @param [Hash] options
    # @option options [Boolean] :unique ensures only one link is output for every
    #     content type, e.g. as required by atom
    # @option options [Array<String>] :exclude array of format shortnames to not include in the output
    # @deprecated moved to ShowPresenter#link_rel_alternates
    def link_rel_alternates(options = {})
      show_presenter.link_rel_alternates(options)
    end
    deprecation_deprecate link_rel_alternates: "use ShowPresenter#link_rel_alternates instead"

    ##
    # Get the document's "title" to display in the <title> element.
    # (by default, use the #document_heading)
    #
    # @see #document_heading
    # @return [String]
    # @deprecated use ShowPresenter#html_title instead
    def document_show_html_title
      show_presenter.html_title
    end
    deprecation_deprecate document_show_html_title: "use ShowPresenter#html_title instead"

    ##
    # Render the document index heading
    #
    # @overload render_document_index_label(field, opts)
    #   @param [Symbol, Proc, String] field Render the given field or evaluate the proc or render the given string
    #   @param [Hash] opts
    # @deprecated use IndexPresenter#label instead
    def render_document_index_label(*args)
      index_presenter.label(*args)
    end
    deprecation_deprecate render_document_index_label: "use IndexPresenter#label instead"

    ##
    # Render the index field label for a document
    #
    # Allow an extention point where information in the document
    # may drive the value of the field
    # @overload render_index_field_value(field, opts)
    #   @param [String] field
    #   @param [Hash] opts
    #   @option opts [String] :value
    # @deprecated use IndexPresenter#field_value instead
    def render_index_field_value *args
      index_presenter.field_value(*args)
    end
    deprecation_deprecate render_index_field_value: "use IndexPresenter#field_value instead"

    ##
    # Render the show field value for a document
    #
    #   Allow an extention point where information in the document
    #   may drive the value of the field
    #
    # @overload render_index_field_value(field, options)
    #   @param [String] field
    #   @param [Hash] options
    #   @option options [String] :value
    #   @deprecated use ShowPresenter#field_value
    def render_document_show_field_value *args
      show_presenter.field_value(*args)
    end
    deprecation_deprecate render_document_show_field_value: "use ShowPresenter#field_value instead"

    ##
    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_search
    # @param [String] _field name
    # @param [Blacklight::Configuration::Field] field_config solr field configuration
    # @param [Hash] options additional options to pass to the rendering helpers
    # @deprecated
    def get_field_values _field, field_config, options = {}
      field_values(field_config, options)
    end
    deprecation_deprecate get_field_values: 'Use field_values instead'

    ##
    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_search
    # @param [Blacklight::Configuration::Field] field_config solr field configuration
    # @param [Hash] options additional options to pass to the rendering helpers
    def field_values(field_config, options={})
      FieldPresenter.new(@controller, @document, field_config, options).render
    end
    deprecation_deprecate field_values: 'Use ShowPresenter or IndexPresenter field_values instead'

    # @deprecated
    def render_field_value(values, field_config = Configuration::NullField.new)
      field_values(field_config, value: Array(values))
    end
    deprecation_deprecate render_field_value: 'Use FieldPresenter instead'

    # @deprecated
    def render_values(values, field_config = Configuration::NullField.new)
      field_values(field_config, value: Array(values))
    end
    deprecation_deprecate render_values: 'Use FieldPresenter instead'

    private

      def index_presenter
        @controller.index_presenter(@document)
      end

      def show_presenter
        @controller.show_presenter(@document)
      end
  end
end
