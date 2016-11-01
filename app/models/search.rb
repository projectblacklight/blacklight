# frozen_string_literal: true
class Search < ActiveRecord::Base
  belongs_to_arguments = { optional: true } if Rails.version >= '5.0.0'

  belongs_to :user, belongs_to_arguments

  serialize :query_params

  attr_accessible :query_params if Blacklight::Utils.needs_attr_accessible?

  # A Search instance is considered a saved search if it has a user_id.
  def saved?
    user_id?
  end

  # delete old, unsaved searches
  def self.delete_old_searches(days_old)
    raise ArgumentError, 'days_old is expected to be a number' unless days_old.is_a?(Numeric)
    raise ArgumentError, 'days_old is expected to be greater than 0' if days_old <= 0
    where(['created_at < ? AND user_id IS NULL', Time.zone.today - days_old]).destroy_all
  end
end
