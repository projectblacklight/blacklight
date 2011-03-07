class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users do |t|
      t.string :login, :unique=>true, :null=>false
      t.string :email, :unique=>true
      t.string :crypted_password
      t.text :last_search_url
      t.datetime :last_login
      t.timestamps
    end
  end
  
  def self.down
    drop_table :users
  end
end