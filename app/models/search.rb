# frozen_string_literal: true

class Search < ApplicationRecord
  belongs_to :user, optional: true

  # use a backwards-compatible serializer until the Rails API stabilizes and we can evaluate for major-revision compatibility
  if ::Rails.version.to_f >= 7.1
    # non-deprecated coder: keyword arg for Rails 7.1+
    serialize :query_params, coder: Blacklight::SearchParamsYamlCoder
  else
    serialize :query_params, Blacklight::SearchParamsYamlCoder
  end

  # A Search instance is considered a saved search if it has a user_id.
  def saved?
    user_id?
  end

  # delete old, unsaved searches
  def self.delete_old_searches(days_old)
    raise ArgumentError, 'days_old is expected to be a number' unless days_old.is_a?(Numeric)
    raise ArgumentError, 'days_old is expected to be greater than 0' if days_old <= 0

    where(['created_at < ? AND user_id IS NULL', Time.zone.today - days_old]).delete_all
  end
end
