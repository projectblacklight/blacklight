module Blacklight::ConfigurationHelperBehavior

  ##
  # Index fields to display for a type of document
  # 
  # @param [SolrDocument] document
  # @return [Array<Blacklight::Solr::Configuration::SolrField>] 
  def index_fields document=nil
    blacklight_config.index_fields
  end

  # Used in the document_list partial (search view) for building a select element
  def sort_fields
    blacklight_config.sort_fields.map { |key, x| [x.label, x.key] }
  end

  # Used in the search form partial for building a select tag
  def search_fields
    search_field_options_for_select
  end

  # used in the catalog/_show/_default partial
  def document_show_fields document=nil
    blacklight_config.show_fields
  end

  ##
  # Look up the label for the index field
  def index_field_label document, field
    label = index_fields(document)[field].label

    solr_field_label(
      label, 
      :"blacklight.search.fields.index.#{field}",
      :"blacklight.search.fields.#{field}"
    )
  end

  ##
  # Look up the label for the show field
  def document_show_field_label document, field
    label = document_show_fields(document)[field].label
    
    solr_field_label(
      label, 
      :"blacklight.search.fields.show.#{field}",
      :"blacklight.search.fields.#{field}"
    )
  end

  ##
  # Look up the label for the facet field
  def facet_field_label field
    label = blacklight_config.facet_fields[field].label

    solr_field_label(
      label, 
      :"blacklight.search.fields.facet.#{field}",
      :"blacklight.search.fields.#{field}"
    )
  end

  ##
  # Look up the label for a solr field.
  #
  # @overload
  #   @param [Symbol] an i18n key 
  #
  # @overload
  #   @param [String] default label to display if the i18n look up fails
  #   @param [Symbol] i18n keys to attempt to look up 
  #     before falling  back to the label
  #   @param [Symbol] any number of additional keys
  #   @param [Symbol] ...
  def solr_field_label label, *i18n_keys
    if label.is_a? Symbol
      return t(label)
    end

    first, *rest = i18n_keys

    rest << label

    t(first, default: rest)
  end
  
  ##
  # Get the default index view type
  def default_document_index_view_type
    blacklight_config.view.keys.first
  end

  ##
  # Check if there are alternative views configuration
  def has_alternative_views?
    blacklight_config.view.keys.length > 1
  end

  ##
  #  Maximum number of results for spell checking
  def spell_check_max
    blacklight_config.spell_max
  end

  # Used in the document list partial (search view) for creating a link to the document show action
  def document_show_link_field document=nil
    blacklight_config.view_config(document_index_view_type).title_field.to_sym
  end

  ##
  # Default sort field
  def default_sort_field
    blacklight_config.sort_fields.first.last if blacklight_config.sort_fields.first
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
end
