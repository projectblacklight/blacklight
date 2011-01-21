class Search < ActiveRecord::Base
  
  belongs_to :user
  
  serialize :query_params
  
  # A Search instance is considered a saved search if it has a user_id.
  def saved?
    self.user_id?
  end
  
  # delete old, unsaved searches
  def self.delete_old_searches(days_old)
    raise ArgumentError.new('days_old is expected to be a number') unless days_old.is_a?(Numeric)
    raise ArgumentError.new('days_old is expected to be greater than 0') if days_old <= 0
    self.destroy_all(['created_at < ? AND user_id IS NULL', Date.today - days_old])
  end
  
end