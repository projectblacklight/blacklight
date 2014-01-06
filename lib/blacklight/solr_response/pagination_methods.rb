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

  def model_name
    if !docs.empty? and docs.first.respond_to? :model_name
      docs.first.model_name
    end
  end

  ## Methods in kaminari master that we'd like to use today.
  # Next page number in the collection
  def next_page
    current_page + 1 unless last_page?
    end

  # Previous page number in the collection
  def prev_page
    current_page - 1 unless first_page?
  end
end