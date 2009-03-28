require 'will_paginate'
require 'will_paginate/collection'
require 'will_paginate/view_helpers'

#
# Override WillPaginate - inserts commas into large page numbers
# example: 443719 becomes 443,719
#

class WillPaginate::LinkRenderer
  
  alias_method :orig_page_link_or_span, :page_link_or_span
  
  def page_link_or_span(page, span_class = 'current', text = nil)
    # format the page number, unless there is first/last page text (the last arg)
    text ||= @template.number_with_delimiter(page)
    orig_page_link_or_span(page, span_class, text)
  end
  
end