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


require 'test/unit'
require '../lib/flare'

class FlareContextFilterQueryTest < Test::Unit::TestCase
  
  def setup
    @flare=Flare::Context.new({:solr_url=>'http://localhost:8983/solr'})
    # add using string
    @flare.add_textual_filter('jazz')
    # add using object
    @flare.add_filter(Flare::Context::TextualFilter.new('bebop'))
    @flare.add_textual_filter('death metal', true)
    @flare.add_faceted_filter('music_category','MT')
    # add using object
    @flare.add_filter(Flare::Context::FacetedFilter.new('music_category','M3', true))
  end
  
  def test_highlighting_query
    v = '(jazz) AND (bebop) AND -(death metal)'
    assert v == @flare.highlighting_query
  end
  
  def test_highlighting_query_is_textual_query
    assert @flare.highlighting_query == @flare.filters.generate_textual_query
  end
  
  def test_full_query
    v='music_category_facet:"MT" AND -music_category_facet:"M3" AND (jazz) AND (bebop) AND -(death metal)'
    assert v == @flare.filters.generate_query
  end
  
  def test_full_query_array
    v=['music_category_facet:"MT"', '-music_category_facet:"M3"', '(jazz)', '(bebop)', '-(death metal)']
    assert v == @flare.filters.generate_queries
  end
  
  def test_textual_query
    v='(jazz) AND (bebop) AND -(death metal)'
    assert v == @flare.filters.generate_textual_query
  end
  
  def test_textual_query_array
    v = ['(jazz)', '(bebop)', '-(death metal)']
    assert v == @flare.filters.generate_textual_queries
  end
  
  def test_faceted_query
    q='music_category_facet:"MT" AND -music_category_facet:"M3"'
    assert q == @flare.filters.generate_faceted_query
  end
  
  def test_faceted_query_array
    v = ['music_category_facet:"MT"', '-music_category_facet:"M3"']
    assert v == @flare.filters.generate_faceted_queries
  end
  
  def test_add_filter
    filter = Flare::Context::TextualFilter.new('latin')
    @flare.add_filter(filter)
    v = '(jazz) AND (bebop) AND -(death metal) AND (latin)'
    assert v == @flare.filters.generate_textual_query
    #
    filter = Flare::Context::FacetedFilter.new('country', 'portugal')
    @flare.add_filter(filter)
    v = ['music_category_facet:"MT"', '-music_category_facet:"M3"', 'country_facet:"portugal"']
    assert v == @flare.filters.generate_faceted_queries
  end
  
  def test_init_filters
    flare = @flare
    assert 0 != flare.filters.total_filters
    flare.init_filters
    assert 0 == flare.filters.total_filters
  end
  
end