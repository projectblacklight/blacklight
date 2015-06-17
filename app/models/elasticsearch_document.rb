require 'elasticsearch/persistence/model'

class ElasticsearchDocument
  include Blacklight::Document
  include Elasticsearch::Persistence::Model

  def self.facetable field, type
    attribute field, type, mapping: { 
      fields: {
        field: { type: 'string' },
        raw: { type: 'string', index: 'not_analyzed' }
      }
    } 
  end
  
  def self.sortable field, type
    attribute field, type, mapping: { 
      fields: {
        field: { type: 'string' },
        raw: { type: 'string', index: 'not_analyzed' }
      }
    } 
  end

  facetable :lc_1letter_facet, String
  attribute :author_t, String
  attribute :marc_display, String
  attribute :published_display, String
  attribute :author_display, String
  attribute :lc_callnum_display, String
  attribute :title_t, String
  attribute :pub_date, String
  sortable :pub_date_sort, String
  facetable :format, String
  attribute :material_type_display, String
  facetable :lc_b4cutter_facet, String
  attribute :title_display, String
  sortable :title_sort, String
  sortable :author_sort, String
  attribute :title_addl_t, String
  attribute :author_addl_t, String
  facetable :lc_alpha_facet, String
  facetable :language_facet, String
  attribute :subtitle_display, String
  attribute :author_vern_display, String
  attribute :subject_addl_t, String
  facetable :subject_era_facet, String
  attribute :isbn_t, String
  facetable :subject_geo_facet, String
  facetable :subject_topic_facet, String
  attribute :title_series_t, String
  attribute :subtitle_t, String
  attribute :title_vern_display, String
  attribute :published_vern_display, String
  attribute :subtitle_vern_display, String
  attribute :subject_t, String
  attribute :title_added_entry_t, String
  attribute :url_suppl_display, String
  
  def to_partial_path
    'catalog/document'
  end

  def key? k
    attributes.include? k.to_sym
  end

  def _source
    self
  end

end