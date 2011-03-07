# Upgrades Acts As Taggable
class ActsAsTaggableOnMigration < ActiveRecord::Migration
  def self.up

    change_table :taggings do |t|
      t.integer :tagger_id
      # You should make sure that the column created is
      # long enough to store the required class names.
      t.string :tagger_type      
      t.string :context
    end
    
    remove_index :taggings, [:taggable_id, :taggable_type]
    add_index :taggings, [:taggable_id, :taggable_type, :context]
  end
  
  def self.down    
    change_table :taggings do |t|
      t.remove :tagger_id, :tagger_type, :context    
    end
    remove_index :taggings, [:taggable_id, :taggable_type, :context]
    add_index :taggings, [:taggable_id, :taggable_type]
  end

end
