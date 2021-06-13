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

  ##
  # Should return response documents size, not hash size
  def size
    total_count
  end

  ##
  # Meant to have the same signature as Kaminari::PaginatableArray#entry_name
  def entry_name(options)
    I18n.t('blacklight.entry_name.default', count: options[:count])
  end
end
