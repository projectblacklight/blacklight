require 'will_paginate'
require 'will_paginate/collection'
require 'will_paginate/view_helpers'

#
# Inserts commas into large page numbers
# example: 443719 becomes 443,719
#
# Note: To use this class, please call:
# <%= will_paginate(@users, :renderer => CommaLinkRenderer) %>

class CommaLinkRenderer < WillPaginate::ViewHelpers::LinkRenderer

  protected

  # Just overriding the page_number method, so that large numbers are 
  # contain appropriate commas. 
  def page_number(page)
    unless page == current_page
      text = @template.number_with_delimiter(page)
      link(text, page, :rel => rel_value(page))
    else
      tag(:em, page)
    end
  end
  
end
  

# The old method overrode page_link_or_span via a monkey patch.
# These methods no longer exist in the latest version of will_paginate
# and the prefered method is to subclass the link renderer with a 
# custom render as shown above.
# see: http://thewebfellas.com/blog/2010/8/22/revisited-roll-your-own-pagination-links-with-will_paginate-and-rails-3
#  alias_method :orig_page_link_or_span, :page_link_or_span  
#  def page_link_or_span(page, span_class = 'current', text = nil)
    # format the page number, unless there is first/last page text (the last arg)
#    text ||= @template.number_with_delimiter(page)
#    orig_page_link_or_span(page, span_class, text)
#  end
  
#end
