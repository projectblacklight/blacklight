class AddAuthlogicFieldsToUsers < ActiveRecord::Migration
  def self.up
    add_column :users, :password_salt, :string
    add_column :users, :persistence_token, :string
    add_column :users, :current_login_at, :datetime
    rename_column :users, :last_login, :last_login_at
  end

  def self.down
    remove_column :users, :current_login_at
    rename_column :users, :last_login_at, :last_login
    remove_column :users, :persistence_token
    remove_column :users, :password_salt
  end
end
