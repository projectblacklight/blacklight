# The ASF licenses this file to You under the Apache License, Version 2.0
# (the "License"); you may not use this file except in compliance with
# the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require 'flare/pagination'

class Flare::Context
  
  attr_accessor :sort, :config
  attr_reader :dataset, :filters, :facet_fields, :text_fields, :connection
  
  def initialize(config={})
    config[:query_params] ||= {}
    validate_config(config)
    
    config[:facet_values_limit] = config[:facet_values_limit].to_s.empty? ? 10 : config[:facet_values_limit]
    
    @config = config
    @connection = Solr::Connection.new(@config[:solr_url])
    @index_info = index_info
    field_setup
    @filters = FilterGroup.new(self.object_id)
    # the container for search results (Solr Response)
    @dataset=nil
  end
  
  def total_filters
    @filters.total
  end
  
  def total_faceted_filters
    @filters.total_faceted
  end
  
  def total_textual_filters
    @filters.total_textual
  end
  
  def is_filtered?
    total_filters > 0
  end
  
  #
  # Extracts values from an existing filter group.
  # This allows filter groups to be separate (save to session/database etc.?)
  # but merged easily for query generation
  #
  # fruit = FilterGroup.new('fruit')
  # fruit.add_faceted_filter('color', 'red')
  # fruit.add_faceted_filter('color', 'orange')
  # fruit.add_textual_filter('sweet fruit')
  # flare_context.import(fruit)
  #
  
  #
  # IS THIS REALLY NEEDED? - mwm4n
  #
  #def import(group)
  #  if group.class != Flare::Context::FilterGroup
  #    raise 'Must be instance of Flare::Context::FilterGroup'
  #  end
  #  group.textual_filters.each do |f|
  #    add_filter(f.clone)
  #  end
  #  group.faceted_filters.each do |f|
  #    add_filter(f.clone)
  #  end
  #end
  
  #
  # Adds a textual filter using variables
  #
  def add_faceted_filter(field,value,negate=false)
    @filters.add_faceted_filter(FacetedFilter.new(field, value, negate))
  end
  
  #
  # Adds a faceted filter using variables
  #
  def add_textual_filter(value,negate=false)
    @filters.add_textual_filter(TextualFilter.new(value, negate))
  end
  
  #
  # Adds a faceted or textual filter
  # using filter instance type
  #
  def add_filter(filter)
    @filters.add_filter(filter)
  end
  
  #
  # Clears the filter values within the groups
  #
  def init_filters
    @filters.init_filters
  end
  
  #
  # Execute the search
  # page -- (rows
  #
  def search(page, rows_per_page=10, select_fields=fields())
    page, start = Flare::Pagination.normalize_page_and_start(page, rows_per_page)
    query_type = @config[:solr_query_type] || :dismax
    query_config = @config[:query_params]
    solr_params = query_config.merge(
      :query => @filters.generate_textual_query,
      :filter_queries => @filters.generate_faceted_queries,
      :start => start,
      :rows => rows_per_page,
      :facets => {
        :fields=>facet_fields_config(),
        :limit => @config[:facet_values_limit], :mincount => 1, :sort => :alpha,
        :queries => [@filters.generate_query]
      },
      :field_list => select_fields + ['score', 'id'],
      :highlighting => {:field_list => @text_fields},
      :sort => @sort
    )
    request = Solr::Request::Standard.new(solr_params)
    response = @connection.send(request)
    response.extend Flare::Pagination
    response.paginate(page, rows_per_page)
    # Making this part of the flare instance
    # allows a more (imho) intuitive interface:
    # @flare.result.each
    # @flare.result.can_paginate?
    # while keeping query/filter code in flare:
    # @flare.is_filtered?
    @dataset=response
    true
  end
  
  #
  # Find a document by id
  #
  def doc_by_id(id)
    request = Solr::Request::Standard.new(:query => "id:\"#{id}\"")
    @connection.send(request).hits[0]
  end
  
  #
  # The available facet values for a given facet field
  #
  def facet_values(field, limit=-1, prefix=nil)
    req = Solr::Request::Standard.new(
      :query => @filters.generate_textual_query,
      :filter_queries => @filters.generate_faceted_queries,
      :facets => {
        :fields => [field],
        :mincount => 1,
        :limit => limit,
        :prefix => prefix,
        :missing => true,
        :sort => :count
      },
      :rows => 0
    )
    results = @connection.send(req)
    results.field_facets(field)
  end
  
  #
  # Returns the textual query for highlighting
  #
  def highlighting_query
    @filters.generate_textual_query
  end
  
  #
  # index of all (text and facet) field names
  #
  def fields(options={})
    selective_get(@facet_fields + @text_fields, options)
  end
  
  #
  # index of all _facet type field names
  #
  def facet_fields(options={})
    puts "facet_fields == #{options.inspect}"
    selective_get(@facet_fields, options)
  end
  
  #
  # index of all _text type field names
  #
  def text_fields(options={})
    selective_get(@text_fields, options)
  end
  
  private
  
  #
  # provide a source and an options hash:
  # get only id and name:
  # selective_get(my_data, {:only=>['id', 'name']})
  # get all except for id and name:
  # selective_get(my_data, {:except=>['id', 'name']})
  #
  def selective_get(source, options)
    options.reject! {|k,v|v.to_s.empty?}
    if options[:only].is_a? Array
      options[:only].reject! {|v|v.to_s.empty?}
      return options[:only] & source
    end
    if options[:except].is_a? Array
      options[:except].reject! {|v|v.to_s.empty?}
      return source - options[:except]
    end
    source
  end
  
  def facet_fields_config
    if @config[:facet_field_params]
      values=[]
      @facet_fields.each do |v|
        k=v.to_sym
        if @config[:facet_field_params][k]
          values << {k=>@config[:facet_field_params][k]}
        else
          values << k
        end
      end
      return values
    end
    @facet_fields
  end
  
  #
  # Returns info on the Solr schema/index
  #
  def index_info
    @connection.send(Solr::Request::IndexInfo.new)
  end
  
  #
  # Specifies desired facet fields and text fields
  #
  def field_setup
    facets_excluded = @config[:facets_exclude] ? @config[:facets_exclude].collect {|e| e.to_s} : []
    @facet_fields = @index_info.field_names.find_all {|v| v =~ /_facet$/} - facets_excluded
    texts_excluded = @config[:texts_exclude] ? @config[:texts_exclude].collect {|e| e.to_s} : []
    @text_fields = @index_info.field_names.find_all {|v| v =~ /_text$/} - texts_excluded
  end
  
  #
  # Validates the config passed into the constructor
  # - validate required
  # if the config keys mixed with the required keys don't == required keys
  # See Ruby Array#&
  # - validate optional
  #
  def validate_config(config)
    map=valid_config(config)
    if (config.keys & map[:required]) != map[:required]
      raise "Invalid config. Required settings are: #{map[:required].join(' | ')}"
    end
    (config.keys - map[:required]).each do |k|
      if ! map[:optional].include? k
        raise "Invalid config setting: \"#{k}\". Optional settings are: #{map[:optional].join(' | ')}"
      end
    end
  end
  
  #
  # Defines/returns a valid config map
  # :solr_url -required- http address
  # :solr_query_type -- dismax/standard etc.
  # :query_params -- params that get merged to the Solr::Connection
  # :facets_exclude -- facets to exclude
  # :texts_exclude -- text fields to exclude
  #
  def valid_config(config={})
    {
      :required=>[:solr_url],
      :optional=>[:facets_exclude,:texts_exclude,:solr_query_type,:query_params,:facet_field_params, :facet_values_limit]
    }
  end
  
end