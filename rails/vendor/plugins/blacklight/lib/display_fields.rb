module DisplayFields
  
  LABEL = 'display_fields'

  class << self
    attr_accessor :show_view, :index_view, :facet, :marc_storage_field, :index_view_fields, :show_view_fields
  end
  
  def self.init
    
    solr_config = YAML::load(File.open("#{RAILS_ROOT}/config/solr.yml"))
    raise "The " + LABEL + " settings were not found in the solr.yml config" unless solr_config[LABEL]
    raise "The facet_fields settings were not found in the solr.yml config" unless solr_config['facet_fields']
        
    DisplayFields.show_view = {
      :html_title=>solr_config[LABEL]['show_view_html_title'],
      :heading=>solr_config[LABEL]['show_view_record_heading'],
      :display_type=>solr_config[LABEL]['record_display_type']
    }
    
    DisplayFields.index_view = {
      :show_link=>solr_config[LABEL]['index_view_show_link'],
      :num_per_page=>solr_config[LABEL]['index_view_num_per_page'],
      :record_display_type=>solr_config[LABEL]['record_display_type']
    }
        
    DisplayFields.facet = {
      :field_names=>solr_config['facet_fields']
    }
    
    DisplayFields.index_view_fields = {
      :field_names=>solr_config['index_view_fields']
    }
    
    DisplayFields.show_view_fields = {
      :field_names=>solr_config['show_view_fields']
    }
    
    DisplayFields.marc_storage_field = solr_config[LABEL]['marc_storage_field']
    
  end
  
end