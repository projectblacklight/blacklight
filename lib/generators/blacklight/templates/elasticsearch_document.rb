# frozen_string_literal: true

require 'elasticsearch/persistence/model'

class ElasticsearchDocument
  include Blacklight::Document
  include Elasticsearch::Persistence::Model

  def self.sortable field, type
    attribute field, type, mapping: {
      type: 'keyword'
    }
  end

  attribute :id, String
  attribute :lc_1letter_ssim, String, mapping: {
    type: 'keyword'
  }
  attribute :author_tsim, String
  attribute :marc_ss, String
  attribute :published_ssim, String
  attribute :lc_callnum_ssim, String
  attribute :title_tsim, String
  attribute :pub_date_ssim, String
  sortable :pub_date_si, Integer
  attribute :format, String, mapping: {
    type: 'keyword'
  }
  attribute :material_type_ssim, String
  attribute :lc_b4cutter_ssim, String, mapping: {
    type: 'keyword'
  }
  sortable :title_si, String
  sortable :author_si, String
  attribute :title_addl_tsim, String
  attribute :author_addl_tsim, String
  attribute :lc_alpha_ssim, String, mapping: {
    type: 'keyword'
  }
  attribute :language_ssim, String, mapping: {
    type: 'keyword'
  }
  # attribute :subtitle_display, String
  # attribute :author_vern_display, String
  # attribute :subject_addl_t, String
  # facetable :subject_era_facet, String
  attribute :isbn_ssim, String
  # facetable :subject_geo_facet, String
  # facetable :subject_topic_facet, String
  # attribute :title_series_t, String
  attribute :subtitle_tsim, String
  # attribute :title_vern_display, String
  # attribute :published_vern_display, String
  # attribute :subtitle_vern_display, String
  # attribute :subject_t, String
  # attribute :title_added_entry_t, String
  attribute :url_suppl_ssim, String

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
  # TODO: Remove?
  def to_param
    id
  end

  # Sometimes elasticsearch-model is returning false here even though we've
  # retrieved the document from the store. Possibly because we're using elasticsearch-model
  # to define properties, but elasticsearch as a repository to retreive the model
  def persisted?
    true
  end
end
