# frozen_string_literal: true

require 'elasticsearch/persistence/model'

class ElasticsearchDocument
  include Blacklight::Document
  include Elasticsearch::Persistence::Model

  def self.facetable field, type
    attribute field, type, mapping: {
      fields: {
        field: { type: 'text' },
        raw: { type: 'keyword' }
      }
    }
  end

  def self.sortable field, type
    attribute field, type, mapping: {
      fields: {
        field: { type: 'text' },
        raw: { type: 'keyword' }
      }
    }
  end

  attribute :id, String
  facetable :lc_1letter_ssim, String
  attribute :author_tsim, String
  attribute :marc_ss, String
  attribute :published_ssim, String
  attribute :lc_callnum_ssim, String
  attribute :title_tsim, String
  attribute :pub_date_ssim, String
  sortable :pub_date_si, String
  facetable :format, String
  attribute :material_type_ssim, String
  facetable :lc_b4cutter_ssim, String
  sortable :title_si, String
  sortable :author_si, String
  attribute :title_addl_tsim, String
  attribute :author_addl_tsim, String
  facetable :lc_alpha_ssim, String
  facetable :language_ssim, String

  # attribute :subtitle_display, String
  # attribute :author_vern_display, String
  # attribute :subject_addl_t, String
  # facetable :subject_era_facet, String
  # attribute :isbn_t, String
  # facetable :subject_geo_facet, String
  # facetable :subject_topic_facet, String
  # attribute :title_series_t, String
  # attribute :subtitle_t, String
  # attribute :title_vern_display, String
  # attribute :published_vern_display, String
  # attribute :subtitle_vern_display, String
  # attribute :subject_t, String
  # attribute :title_added_entry_t, String
  # attribute :url_suppl_display, String

  def to_partial_path
    'catalog/document'
  end

  def key? key
    attributes.include? key.to_sym
  end

  def _source
    self
  end

  # Overriding ActiveModel::Conversion to provide an id even for an unsaved object
  # See https://github.com/elastic/elasticsearch-rails/issues/804
  def to_param
    id
  end
end
