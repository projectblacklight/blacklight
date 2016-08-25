module Blacklight::ConfigurationHelperBehavior
  extend Deprecation
  self.deprecation_horizon = 'blacklight 6.0'

  ##
  # Index fields to display for a type of document
  # 
  # @param [SolrDocument] document
  # @return [Array<Blacklight::Solr::Configuration::Field>] 
  def index_fields document=nil
    blacklight_config.index_fields
  end

  # Used in the document_list partial (search view) for building a select element
  def sort_fields
    active_sort_fields.map { |key, x| [x.label, x.key] }
  end
  
  def active_sort_fields
    blacklight_config.sort_fields.select { |sort_key, field_config| should_render_field?(field_config) }
  end

  # Used in the search form partial for building a select tag
  def search_fields
    search_field_options_for_select
  end
  
  # Returns suitable argument to options_for_select method, to create
  # an html select based on #search_field_list. Skips search_fields
  # marked :include_in_simple_select => false
  def search_field_options_for_select
    blacklight_config.search_fields.collect do |key, field_def|
      [field_def.label,  field_def.key] if should_render_field?(field_def)
    end.compact
  end

  # used in the catalog/_show/_default partial
  def document_show_fields document=nil
    blacklight_config.show_fields
  end

  ##
  # Return a label for the currently selected search field.
  # If no "search_field" or the default (e.g. "all_fields") is selected, then return nil
  # Otherwise grab the label of the selected search field.
  # @param [Hash] query parameters
  # @return [String]
  def constraint_query_label(localized_params = params)
    label_for_search_field(localized_params[:search_field]) unless default_search_field?(localized_params[:search_field])
  end

  ##
  # Is the search form using the default search field ("all_fields" by default)?
  # @param [String] the currently selected search_field
  # @return [Boolean]
  def default_search_field?(selected_search_field)
    selected_search_field.blank? || (default_search_field && selected_search_field == default_search_field[:key])
  end

  ##
  # Look up the label for the index field
  def index_field_label document, field
    field_config = index_fields(document)[field]

    field_label(
      :"blacklight.search.fields.index.#{field}",
      :"blacklight.search.fields.#{field}",
      (field_config.label if field_config),
      field.to_s.humanize
    )
  end

  ##
  # Look up the label for the show field
  def document_show_field_label document, field
    field_config = document_show_fields(document)[field]

    field_label(
      :"blacklight.search.fields.show.#{field}",
      :"blacklight.search.fields.#{field}",
      (field_config.label if field_config),
      field.to_s.humanize
    )
  end

  ##
  # Look up the label for the facet field
  def facet_field_label field
    field_config = blacklight_config.facet_fields[field]
    defaults = [:"blacklight.search.fields.facet.#{field}", :"blacklight.search.fields.#{field}"]
    defaults << field_config.label if field_config
    defaults << field.to_s.humanize

    field_label *defaults
  end

  def view_label view
    view_config = blacklight_config.view[view]
    field_label(
      :"blacklight.search.view_title.#{view}",
      :"blacklight.search.view.#{view}",
      view_config.label,
      view_config.title,
      view.to_s.humanize
    )
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
  def field_label *i18n_keys
    first, *rest = i18n_keys.compact

    t(first, default: rest)
  end
  alias_method :solr_field_label, :field_label
  deprecation_deprecate solr_field_label: :field_label
  
  def document_index_views
    blacklight_config.view.select do |k, config|
      should_render_field? config
    end
  end
  
  ##
  # Get the default index view type
  def default_document_index_view_type
    document_index_views.select { |k,config| config.respond_to? :default and config.default }.keys.first || document_index_views.keys.first
  end

  ##
  # Check if there are alternative views configuration
  def has_alternative_views?
    document_index_views.keys.length > 1
  end

  ##
  #  Maximum number of results for spell checking
  def spell_check_max
    blacklight_config.spell_max
  end

  # Used in the document list partial (search view) for creating a link to the document show action
  def document_show_link_field document=nil
    fields = Array(blacklight_config.view_config(document_index_view_type).title_field)

    field = fields.first if document.nil?
    field ||= fields.find { |f| document.has? f }
    field &&= field.try(:to_sym)
    field ||= document.id

    field
  end

  ##
  # Default sort field
  def default_sort_field
    (active_sort_fields.find { |k,config| config.respond_to? :default and config.default } || active_sort_fields.first).try(:last)
  end

  ##
  # The default value for search results per page
  def default_per_page
    blacklight_config.default_per_page || blacklight_config.per_page.first
  end
  
  ##
  # The available options for results per page, in the style of #options_for_select
  def per_page_options_for_select
    blacklight_config.per_page.map do |count|
      [t(:'blacklight.search.per_page.label', :count => count).html_safe, count]
    end
  end
  
  ##
  # Determine whether to render a field by evaluating :if and :unless conditions
  #
  # @param [Blacklight::Solr::Configuration::Field] field_config
  # @return [Boolean]
  def should_render_field? field_config, *args
    evaluate_if_unless_configuration field_config, *args
  end

  ##
  # Evaluate conditionals for a configuration with if/unless attributes
  #
  # @param displayable_config [#if,#unless] an object that responds to if/unless
  # @return [Boolean]
  def evaluate_if_unless_configuration displayable_config, *args
    return displayable_config if displayable_config == true or displayable_config == false
    
    if_value = !displayable_config.respond_to?(:if) ||
                    displayable_config.if.nil? ||
                    evaluate_configuration_conditional(displayable_config.if, displayable_config, *args)
    
    unless_value = !displayable_config.respond_to?(:unless) ||
                      displayable_config.unless.nil? ||
                      !evaluate_configuration_conditional(displayable_config.unless, displayable_config, *args)

    if_value && unless_value
  end
  
  def evaluate_configuration_conditional proc_helper_or_boolean, *args_for_procs_and_methods
    case proc_helper_or_boolean
    when Symbol
      arity = method(proc_helper_or_boolean).arity

      if arity == 0
        send(proc_helper_or_boolean)
      else 
        send(proc_helper_or_boolean, *args_for_procs_and_methods)
      end
    when Proc
      proc_helper_or_boolean.call self, *args_for_procs_and_methods
    else
      proc_helper_or_boolean
    end
  end
end
