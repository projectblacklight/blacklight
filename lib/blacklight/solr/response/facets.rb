# frozen_string_literal: true
require 'ostruct'

module Blacklight::Solr::Response::Facets
  # represents a facet value; which is a field value and its hit count
  class FacetItem < OpenStruct
    def initialize *args
      options = args.extract_options!

      # Backwards-compat method signature
      value = args.shift
      hits = args.shift

      options[:value] = value if value
      options[:hits] = hits if hits

      super(options)
    end

    def label
      super || value
    end

    def as_json(props = nil)
      table.as_json(props)
    end
  end

  # represents a facet; which is a field and its values
  class FacetField
    attr_reader :name, :items
    attr_accessor :missing

    def initialize name, items, options = {}
      @name = name
      @items = items
      @options = options
    end

    def limit
      @options[:limit] || solr_default_limit
    end

    def sort
      @options[:sort] || solr_default_sort
    end

    def offset
      @options[:offset] || solr_default_offset
    end

    def prefix
      @options[:prefix] || solr_default_prefix
    end

    def type
      @options[:type] || 'terms'
    end

    def data
      @options[:data] || {}
    end

    def index?
      sort == 'index'
    end

    def count?
      sort == 'count'
    end

    private

    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.limit
    def solr_default_limit
      100
    end

    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.sort
    def solr_default_sort
      if limit > 0
        'count'
      else
        'index'
      end
    end

    # Per https://wiki.apache.org/solr/SimpleFacetParameters#facet.offset
    def solr_default_offset
      0
    end

    def solr_default_prefix
      nil
    end
  end

  ##
  # Get all the Solr facet data (fields, queries, pivots) as a hash keyed by
  # both the Solr field name and/or by the blacklight field name
  def aggregations
    @aggregations ||= {}.merge(facet_field_aggregations).merge(facet_query_aggregations).merge(facet_pivot_aggregations).merge(json_facet_aggregations)
  end

  def facet_counts
    @facet_counts ||= self['facet_counts'] || {}
  end

  # Returns the hash of all the facet_fields (ie: { 'instock_b' => ['true', 123, 'false', 20] }
  def facet_fields
    @facet_fields ||= begin
      val = facet_counts['facet_fields'] || {}

      # this is some old solr (1.4? earlier?) serialization of facet fields
      if val.is_a? Array
        Hash[val]
      else
        val
      end
    end
  end

  # Returns all of the facet queries
  def facet_queries
    @facet_queries ||= facet_counts['facet_queries'] || {}
  end

  # Returns all of the facet queries
  def facet_pivot
    @facet_pivot ||= facet_counts['facet_pivot'] || {}
  end

  # Merge or add new facet count values to existing response
  def merge_facet(name:, value:, hits: nil)
    if dig('facet_counts', 'facet_fields', name)
      self['facet_counts']['facet_fields'][name] << value << hits
    else
      self['facet_counts']['facet_fields'][name] = [value, hits]
    end
  end

  private

  ##
  # Convert Solr responses of various json.nl flavors to
  def list_as_hash solr_list
    # map
    if solr_list.values.first.is_a? Hash
      solr_list
    else
      solr_list.transform_values do |values|
        if values.first.is_a? Array
          # arrarr
          Hash[values]
        else
          # flat
          Hash[values.each_slice(2).to_a]
        end
      end
    end
  end

  ##
  # Convert Solr's facet_field response into
  # a hash of Blacklight::Solr::Response::Facet::FacetField objects
  def facet_field_aggregations
    list_as_hash(facet_fields).each_with_object({}) do |(facet_field_name, values), hash|
      items = values.map do |value, hits|
        i = FacetItem.new(value: value, hits: hits)

        # legacy solr facet.missing serialization
        if value.nil?
          i.label = I18n.t(:"blacklight.search.fields.facet.missing.#{facet_field_name}", default: [:"blacklight.search.facets.missing"])
          i.fq = "-#{facet_field_name}:[* TO *]"
          i.missing = true
        end

        i
      end

      options = facet_field_aggregation_options(facet_field_name)
      facet_field = FacetField.new(facet_field_name, items, options)

      if values[nil]
        facet_field.missing = items.find(&:missing)
      end

      hash[facet_field_name] = facet_field

      # alias all the possible blacklight config names..
      blacklight_config.facet_fields.select { |_k, v| v.field == facet_field_name }.each_key do |key|
        hash[key] = hash[facet_field_name]
      end if blacklight_config && !blacklight_config.facet_fields[facet_field_name]
    end
  end

  ##
  # Aggregate Solr's facet_query response into the virtual facet fields defined
  # in the blacklight configuration
  def facet_query_aggregations
    return {} unless blacklight_config

    blacklight_config.facet_fields.select { |_k, v| v.query }.each_with_object({}) do |(field_name, facet_field), hash|
      salient_facet_queries = facet_field.query.map { |_k, x| x[:fq] }
      items = facet_queries.select { |k, _v| salient_facet_queries.include?(k) }.reject { |_value, hits| hits.zero? }.map do |value, hits|
        salient_fields = facet_field.query.select { |_key, val| val[:fq] == value }
        key = ((salient_fields.keys if salient_fields.respond_to? :keys) || salient_fields.first).first
        Blacklight::Solr::Response::Facets::FacetItem.new(value: key, hits: hits, label: facet_field.query[key][:label])
      end

      items += facet_query_aggregations_from_json(facet_field)

      items = items.sort_by(&:hits).reverse if facet_field.sort && facet_field.sort.to_sym == :count

      hash[field_name] = Blacklight::Solr::Response::Facets::FacetField.new field_name, items
    end
  end

  def facet_query_aggregations_from_json(facet_field)
    return [] unless self['facets']

    salient_facet_queries = facet_field.query.map { |_k, x| x[:fq] }

    relevant_facet_data = self['facets'].select { |k, _v| salient_facet_queries.include?(k) }.reject { |_key, data| data['count'].zero? }

    relevant_facet_data.map do |key, data|
      salient_fields = facet_field.query.select { |_key, val| val[:fq] == key }
      facet_key = ((salient_fields.keys if salient_fields.respond_to? :keys) || salient_fields.first).first
      Blacklight::Solr::Response::Facets::FacetItem.new(value: facet_key, hits: data[:count], label: facet_field.query[facet_key][:label])
    end
  end

  ##
  # Convert Solr's facet_pivot response into
  # a hash of Blacklight::Solr::Response::Facet::FacetField objects
  def facet_pivot_aggregations
    facet_pivot.each_with_object({}) do |(field_name, values), hash|
      next unless blacklight_config && !blacklight_config.facet_fields[field_name]

      items = values.map do |lst|
        construct_pivot_field(lst)
      end

      # alias all the possible blacklight config names..
      blacklight_config.facet_fields.select { |_k, v| v.pivot && v.pivot.join(",") == field_name }.each_key do |key|
        hash[key] = Blacklight::Solr::Response::Facets::FacetField.new key, items
      end
    end
  end

  ##
  # Recursively parse the pivot facet response to build up the full pivot tree
  def construct_pivot_field lst, parent_fq = {}
    items = Array(lst[:pivot]).map do |i|
      construct_pivot_field(i, parent_fq.merge({ lst[:field] => lst[:value] }))
    end

    Blacklight::Solr::Response::Facets::FacetItem.new(value: lst[:value], hits: lst[:count], field: lst[:field], items: items, fq: parent_fq)
  end

  def construct_json_nested_facet_fields(bucket, parent_fq = {})
    bucket.select { |_, nested| nested.is_a?(Hash) && nested.key?('buckets') }.map do |facet_field_name, nested|
      nested['buckets'].map do |subbucket|
        i = Blacklight::Solr::Response::Facets::FacetItem.new(field: facet_field_name, value: subbucket['val'], hits: subbucket['count'], fq: parent_fq, data: subbucket)

        i.items = construct_json_nested_facet_fields(subbucket, parent_fq.merge(key => subbucket['val'])) if has_json_nested_facets?(subbucket)
        i
      end
    end.flatten
  end

  def has_json_nested_facets?(bucket)
    bucket.any? { |_, nested| nested.is_a?(Hash) && nested.key?('buckets') }
  end

  def json_facet_aggregations
    return {} unless self['facets']

    self['facets'].each_with_object({}) do |(facet_field_name, data), hash|
      next if facet_field_name == 'count'

      items = (data['buckets'] || []).map do |bucket|
        i = Blacklight::Solr::Response::Facets::FacetItem.new(value: bucket['val'], hits: bucket['count'], data: bucket)

        i.items = construct_json_nested_facet_fields(bucket, facet_field_name => bucket['val']) if has_json_nested_facets?(bucket)

        i
      end

      options = facet_field_aggregation_options(facet_field_name).merge(data: data)
      facet_field = FacetField.new(facet_field_name, items, options)

      facet_field.missing = Blacklight::Solr::Response::Facets::FacetItem.new(
        hits: data.dig('missing', 'count'),
        data: data['missing']
      ) if data['missing']

      hash[facet_field_name] = facet_field
    end
  end
end
