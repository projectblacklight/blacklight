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


#
# A collection of text and facet based filters
#
class Flare::Context::FilterGroup
  
  attr_reader :name, :textual_filters, :faceted_filters
  
  BOOLEAN_OP_JOIN=' AND '
  
  def initialize(name)
    @name=name
    init_filters
  end
  
  def init_filters
    @textual_filters=[]
    @faceted_filters=[]
  end
  
  def total
    @textual_filters.size + @faceted_filters.size
  end
  
  def total_faceted
    @faceted_filters.size
  end
  
  def total_textual
    @textual_filters.size
  end
  
  def add_filter(filter)
    if filter.class == Flare::Context::FacetedFilter
      add_faceted_filter(filter)
    elsif filter.class == Flare::Context::TextualFilter
      add_textual_filter(filter)
    else
      raise 'Must be instance of Flare::Context::FacetedFilter or Flare::Context::TextualFilter'
    end
  end
  
  def add_textual_filter(filter)
    if filter.class != Flare::Context::TextualFilter
      raise 'Must be instance of Flare::Context::TextualFilter'
    end
    @textual_filters << filter
  end
  
  def add_faceted_filter(filter)
    if filter.class != Flare::Context::FacetedFilter
      raise 'Must be instance of Flare::Context::FacetedFilter'
    end
    @faceted_filters << filter
  end
  
  def generate_query
    generate_queries.join(BOOLEAN_OP_JOIN)
  end
  
  #
  # Returns array of both faceted and textual queries
  #
  def generate_queries
    generate_faceted_queries + generate_textual_queries
  end
  
  #
  # Array of textual filter queries
  #
  def generate_textual_queries
    return ["*:*"] if @textual_filters.to_s.empty?
    @textual_filters.collect do |tf|
      tf.to_query
    end
  end
  
  #
  # String made from all textual filter queries
  #
  def generate_textual_query
    generate_textual_queries.join(BOOLEAN_OP_JOIN)
  end
  
  #
  # Array of faceted filter queries
  #
  def generate_faceted_queries
    @faceted_filters.collect do |ff|
      ff.to_query
    end
  end
  
  #
  # String made from all faceted filters
  #
  def generate_faceted_query
    generate_faceted_queries.join(BOOLEAN_OP_JOIN)
  end
  
  #def self.build_textual_filters(data)
  #
  #end
  #
  #def self.build_faceted_filters(data)
  #
  #end
  
end