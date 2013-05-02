class SearchLog < ActiveRecord::Base
	belongs_to :user
	belongs_to :search

  attr_accessible :search_id, :user_id
end
