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
    blacklight_config.per_page.first unless blacklight_config.per_page.blank?
  end
end