# -*- encoding : utf-8 -*-

from = if Rails.version > '5'
          ActiveRecord::Migration[5.0]
       else
         ActiveRecord::Migration
       end

class AddPolymorphicTypeToBookmarks < from
  def change
    add_column(:bookmarks, :document_type, :string)

    add_index :bookmarks, :user_id
  end
end
