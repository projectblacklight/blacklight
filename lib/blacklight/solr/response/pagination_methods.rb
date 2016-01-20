# frozen_string_literal: true
module Blacklight::Solr::Response::PaginationMethods

  include Kaminari::PageScopeMethods
  include Kaminari::ConfigurationMethods::ClassMethods

  def limit_value #:nodoc:
    rows
  end

  def offset_value #:nodoc:
    start
  end

  def total_count #:nodoc:
    total
  end
end
