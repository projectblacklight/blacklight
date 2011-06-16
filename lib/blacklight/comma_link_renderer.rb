# -*- encoding : utf-8 -*-
require 'will_paginate/view_helpers/link_renderer'

# Custom link renderer for WillPaginate
# Inserts commas into large page numbers
# example: 443719 becomes 443,719
#
# Note: To use this class, please call:
# <%= will_paginate(@users, :renderer => CommaLinkRenderer) %>

module Blacklight

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
end
