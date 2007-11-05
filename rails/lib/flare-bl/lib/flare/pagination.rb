##########################################################################
# Copyright 2008 Rector and Visitors of the University of Virginia
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
##########################################################################


module Flare::Pagination
  
  attr_reader :page, :per_page
  
  def self.extended(base)
    
  end
  
  #
  # page, start = Flare::Pagination.normalize_page_and_start(page, rows_per_page)
  #
  def self.normalize_page_and_start(page, rows_per_page)
    page = page.to_i
    page = page < 1 ? 1 : page
    start = (page-1) * rows_per_page
    [page,start]
  end
  
  def paginate(page, per_page)
    @page=page
    @per_page=per_page
  end
  
  def can_paginate?
    next_page? || prev_page?
  end
  
  def first_page?
    @page < 2
  end
  
  def last_page?
    @page==total_pages
  end
  
  def total_pages
    (total_hits / @per_page) + 1;
  end
  
  def page_start_index
    calculated_start = @page * @per_page - @per_page + 1
    [calculated_start, 1].max
  end
  
  def page_end_index
    calculated_end = page_start_index + @per_page - 1
    [calculated_end, total_hits].min
  end
  
  def page_indexes
    [page_start_index, page_end_index]
  end
  
  def next_page?
    (total_hits - page_end_index) > 0
  end
  
  def prev_page?
    @page > 1#(page_start_index < 1) && (page_end_index < total_hits)
  end
  
  def prev_page
    prev_page? ? @page-1 : @page
  end
  
  def next_page
    next_page? ? @page+1 : @page
  end
  
end