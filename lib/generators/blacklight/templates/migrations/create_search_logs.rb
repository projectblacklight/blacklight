class CreateSearchLogs < ActiveRecord::Migration
  def self.up
    create_table :search_logs do |t|
      t.integer :search_id
      t.integer :user_id

      t.timestamps
    end
  end
  
  def self.down
    drop_table :search_logs
  end
end
