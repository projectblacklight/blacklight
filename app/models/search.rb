class Search < ActiveRecord::Base
  
  belongs_to :user
  
  serialize :query_params
  
  # A Search instance is considered a saved search if it has a user_id.
  def saved?
    self.user_id?
  end
  
end