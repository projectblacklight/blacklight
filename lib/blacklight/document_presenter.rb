module Blacklight
  class DocumentPresenter
    include ActionView::Helpers::OutputSafetyHelper
    include ActionView::Helpers::TagHelper
    extend Deprecation

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
    # @param [SolrDocument] document
    # @return [String]
    def document_heading
      fields = Array(@configuration.view_config(:show).title_field)
      f = fields.find { |field| @document.has? field }

      if f.nil?
        render_field_value(@document.id)
      else
        render_field_value(@document[f])
      end
    end

    ##
    # Get the document's "title" to display in the <title> element.
    # (by default, use the #document_heading)
    #
    # @see #document_heading
    # @return [String]
    def document_show_html_title
      if @configuration.view_config(:show).html_title_field
        fields = Array(@configuration.view_config(:show).html_title_field)
        f = fields.find { |field| @document.has? field }

        if f.nil?
          render_field_value(@document.id)
        else
          render_field_value(@document[f])
        end
      else
        document_heading
      end
    end

    ##
    # Render a value (or array of values) from a field
    #
    # @param [String] value or list of values to display
    # @param [Blacklight::Solr::Configuration::Field] solr field configuration
    # @return [String]
    def render_field_value value=nil, field_config=nil
      safe_values = Array(value).collect { |x| x.respond_to?(:force_encoding) ? x.force_encoding("UTF-8") : x }

      if field_config and field_config.itemprop
        safe_values = safe_values.map { |x| content_tag :span, x, :itemprop => field_config.itemprop }
      end

      safe_join(safe_values, (field_config.separator if field_config) || field_value_separator)
    end

    ##
    # Render the document index heading
    #
    # @param [Hash] opts (Deprecated)
    # @option opts [Symbol] :label Render the given field from the document
    # @option opts [Proc] :label Evaluate the given proc
    # @option opts [String] :label Render the given string
    # @param [Symbol, Proc, String] field Render the given field or evaluate the proc or render the given string
    def render_document_index_label field, opts ={}
      if field.kind_of? Hash
        Deprecation.warn DocumentPresenter, "Calling render_document_index_label with a hash is deprecated"
        field = field[:label]
      end
      label = case field
      when Symbol
        @document.get(field, :sep => nil)
      when Proc
        field.call(@document, opts)
      when String
        field
      end
      render_field_value label || @document.id
    end

    ##
    # Render the index field label for a document
    #
    #   Allow an extention point where information in the document
    #   may drive the value of the field
    #   @param [String] field
    #   @param [Hash] opts
    #   @options opts [String] :value
    def render_index_field_value field, options = {}
      field_config = @configuration.index_fields[field]
      value = options[:value] || get_field_values(field, field_config, options)

      render_field_value value, field_config
    end

    ##
    # Render the show field value for a document
    #
    #   Allow an extention point where information in the document
    #   may drive the value of the field
    #   @param [String] field
    #   @param [Hash] options
    #   @options opts [String] :value
    def render_document_show_field_value field, options={}
      field_config = @configuration.show_fields[field]
      value = options[:value] || get_field_values(field, field_config, options)

      render_field_value value, field_config
    end

    ##
    # Get the value for a document's field, and prepare to render it.
    # - highlight_field
    # - accessor
    # - solr field
    #
    # Rendering:
    #   - helper_method
    #   - link_to_search
    # TODO : maybe this should be merged with render_field_value, and the ugly signature 
    # simplified by pushing some of this logic into the "model"
    # @param [SolrDocument] document
    # @param [String] field name
    # @param [Blacklight::Solr::Configuration::Field] solr field configuration
    # @param [Hash] options additional options to pass to the rendering helpers
    def get_field_values field, field_config, options = {}
      # retrieving values
      value = case    
        when (field_config and field_config.highlight)
          # retrieve the document value from the highlighting response
          @document.highlight_field(field_config.field).map { |x| x.html_safe } if @document.has_highlight_field? field_config.field
        when (field_config and field_config.accessor)
          # implicit method call
          if field_config.accessor === true
            @document.send(field)
          # arity-1 method call (include the field name in the call)
          elsif !field_config.accessor.is_a?(Array) && @document.method(field_config.accessor).arity != 0
            @document.send(field_config.accessor, field)
          # chained method calls
          else
            Array(field_config.accessor).inject(@document) do |result, method|
              result.send(method)
            end
          end
        else
          # regular solr
          @document.get(field, :sep => nil) if field
      end

      # rendering values
      case
        when (field_config and field_config.helper_method)
          @controller.send(field_config.helper_method, options.merge(:document => @document, :field => field, :value => value))
        when (field_config and field_config.link_to_search)
          link_field = if field_config.link_to_search === true
            field_config.key
          else
            field_config.link_to_search
          end

          Array(value).map do |v|
            @controller.link_to render_field_value(v, field_config), @controller.search_action_path(@controller.add_facet_params(link_field, v, {}))
          end if field
        else
          value
        end
    end

    ##
    # Default separator to use in #render_field_value
    #
    # @return [String]
    def field_value_separator
      ', '
    end

  end
end
