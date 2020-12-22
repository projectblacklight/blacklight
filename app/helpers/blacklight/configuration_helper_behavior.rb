# frozen_string_literal: true
module Blacklight::ConfigurationHelperBehavior
  extend Deprecation

  ##
  # Return the available sort fields
  # @return [Array<Blacklight::Configuration::Field>]
  def active_sort_fields
    blacklight_config.sort_fields.select { |_sort_key, field_config| should_render_field?(field_config) }
  end

  # used in the catalog/_show partial
  # @return [Array<Blacklight::Configuration::Field>]
  def document_show_fields _document = nil
    Deprecation.warn(self, "document_show_fields is deprecated and will be removed in Blacklight 8. Use ShowPresenter#fields instead")
    blacklight_config.show_fields
  end

  ##
  # Is the search form using the default search field ("all_fields" by default)?
  # @param [String] selected_search_field the currently selected search_field
  # @return [Boolean]
  def default_search_field?(selected_search_field)
    Deprecation.silence(Blacklight::SearchFields) do
      selected_search_field.blank? || (default_search_field && selected_search_field == default_search_field[:key])
    end
  end

  ##
  # Look up the label for the index field
  # @deprecated
  # @return [String]
  def index_field_label document, field
    field_config = blacklight_config.index_fields_for(document_presenter(document).display_type)[field]
    field_config ||= Blacklight::Configuration::NullField.new(key: field)

    field_config.display_label('index')
  end
  deprecation_deprecate :index_field_label

  ##
  # Look up the label for the show field
  # @deprecated
  # @return [String]
  def document_show_field_label document, field
    field_config = blacklight_config.show_fields_for(document_presenter(document).display_type)[field]
    field_config ||= Blacklight::Configuration::NullField.new(key: field)

    field_config.display_label('show')
  end
  deprecation_deprecate :document_show_field_label

  ##
  # Look up the label for the facet field
  # @return [String]
  def facet_field_label field
    field_config = blacklight_config.facet_fields[field]
    field_config ||= Blacklight::Configuration::NullField.new(key: field)

    field_config.display_label('facet')
  end

  # Shortcut for commonly needed operation, look up display
  # label for the key specified.
  # @return [String]
  def label_for_search_field(key)
    field_config = blacklight_config.search_fields[key]
    return if key.nil? && field_config.nil?

    field_config ||= Blacklight::Configuration::NullField.new(key: key)

    field_config.display_label('search')
  end

  # @return [String]
  def sort_field_label(key)
    field_config = blacklight_config.sort_fields[key]
    field_config ||= Blacklight::Configuration::NullField.new(key: key)

    field_config.display_label('sort')
  end

  ##
  # Look up the label for a solr field.
  #
  # @overload label
  #   @param [Symbol] an i18n key
  #
  # @overload label, i18n_key, another_i18n_key, and_another_i18n_key
  #   @param [String] default label to display if the i18n look up fails
  #   @param [Symbol] i18n keys to attempt to look up
  #     before falling  back to the label
  #   @param [Symbol] any number of additional keys
  #   @param [Symbol] ...
  # @return [String]
  def field_label *i18n_keys
    first, *rest = i18n_keys.compact

    t(first, default: rest)
  end

  # @return [Hash<Symbol => Blacklight::Configuration::ViewConfig>]
  def document_index_views
    blacklight_config.view.select do |_k, config|
      should_render_field? config
    end
  end

  # filter #document_index_views to just views that should display in the view type control
  def document_index_view_controls
    document_index_views.select do |_k, config|
      config.display_control.nil? || blacklight_configuration_context.evaluate_configuration_conditional(config.display_control)
    end
  end

  ##
  # Get the default index view type
  def default_document_index_view_type
    document_index_views.select { |_k, config| config.respond_to?(:default) && config.default }.keys.first || document_index_views.keys.first
  end

  ##
  # Default sort field
  def default_sort_field
    (active_sort_fields.find { |_k, config| config.respond_to?(:default) && config.default } || active_sort_fields.first)&.last
  end

  ##
  # The available options for results per page, in the style of #options_for_select
  def per_page_options_for_select
    return [] if blacklight_config.per_page.blank?

    blacklight_config.per_page.map do |count|
      [t(:'blacklight.search.per_page.label', count: count).html_safe, count]
    end
  end

  ##
  # Determine whether to render a field by evaluating :if and :unless conditions
  #
  # @param [Blacklight::Solr::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_field?(field_config, *args)
    blacklight_configuration_context.evaluate_if_unless_configuration field_config, *args
  end
end
