# -*- encoding : utf-8 -*-
class AddUserTypesToBookmarksSearches < ActiveRecord::Migration
  def self.up
    add_column :searches, :user_type, :string
    add_column :bookmarks, :user_type, :string
    execute <<-SQL
       UPDATE searches set user_type="<%=model_name%>"
    SQL
    execute <<-SQL
       UPDATE bookmarks set user_type="<%=model_name%>"
    SQL
  end

  def self.down
    remove_column :searches, :user_type, :string
    remove_column :bookmarks, :user_type, :string
  end
end
