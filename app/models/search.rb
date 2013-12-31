# -*- encoding : utf-8 -*-
class Search < ActiveRecord::Base

  belongs_to :user

  serialize :query_params

  if Rails::VERSION::MAJOR < 4
    attr_accessible :query_params 
  
    scope :none, where(:id => nil).where("id IS NOT ?", nil)
  end

  # delete old, unsaved searches
  def self.delete_old_searches(days_old)
    raise ArgumentError.new('days_old is expected to be a number') unless days_old.is_a?(Numeric)
    raise ArgumentError.new('days_old is expected to be greater than 0') if days_old <= 0
    self.destroy_all(['created_at < ?', Date.today - days_old])
  end
  
end
