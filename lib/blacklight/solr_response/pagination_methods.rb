module Blacklight::SolrResponse::PaginationMethods

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

  def cursor_mark
    params['cursorMark']
  end

  def next_cursor_mark
    self['nextCursorMark'] unless self['nextCursorMark'] == params['cursorMark']
  end
end
