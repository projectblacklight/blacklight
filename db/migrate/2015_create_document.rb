# -*- encoding : utf-8 -*-
class CreateDocument < ActiveRecord::Migration
  def self.up
    create_table :documents do |t|
      
      t.string :lc_1letter_facet
      t.string :author_t
      t.string :marc_display
      t.string :published_display
      t.string :author_display
      t.string :lc_callnum_display
      t.string :title_t
      t.string :pub_date
      t.string :pub_date_sort
      t.string :format
      t.string :material_type_display
      t.string :lc_b4cutter_facet
      t.string :title_display
      t.string :title_sort
      t.string :author_sort
      t.string :title_addl_t
      t.string :author_addl_t
      t.string :lc_alpha_facet
      t.string :language_facet
      t.string :subtitle_display
      t.string :author_vern_display
      t.string :subject_addl_t
      t.string :subject_era_facet
      t.string :isbn_t
      t.string :subject_geo_facet
      t.string :subject_topic_facet
      t.string :title_series_t
      t.string :subtitle_t
      t.string :title_vern_display
      t.string :published_vern_display
      t.string :subtitle_vern_display
      t.string :subject_t
      t.string :title_added_entry_t
      t.string :url_suppl_display

      t.timestamps
    end
  end

  def self.down
    drop_table :documents
  end
end
