class Search < ActiveRecord::Base
  belongs_to :user

  def query_params
    @query_params ||= YAML.load(read_attribute(:query_params))
  end
  def query_params=(qp)
    @query_params = nil
    write_attribute(:query_params, YAML.dump(qp))
  end
  
  # A Search instance is considered a saved search if it has a user_id.
  def saved?
    self.user_id?
  end
end
