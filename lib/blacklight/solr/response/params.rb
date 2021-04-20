# frozen_string_literal: true
module Blacklight::Solr::Response::Params
  # From https://solr.apache.org/guide/8_8/json-request-api.html#supported-properties-and-syntax
  QUERY_PARAMETER_TO_JSON_PARAMETER_MAPPING = {
    q: :query,
    fq: :filter,
    start: :offset,
    rows: :limit,
    fl: :fields,
    sort: :sort
  }.freeze

  def params
    header['params'] || request_params
  end

  def start
    search_builder&.start || single_valued_param(:start).to_i
  end

  def rows
    search_builder&.rows || single_valued_param(:rows).to_i
  end

  def sort
    search_builder&.sort || single_valued_param(:sort)
  end

  def facet_field_aggregation_options(facet_field_name)
    defaults = {
      sort: single_valued_param(:'facet.sort'),
      limit: single_valued_param(:"facet.limit")&.to_i || 100,
      offset: single_valued_param(:"facet.offset")&.to_i || 0,
      prefix: single_valued_param(:"facet.prefix")
    }

    json_facet = json_params.dig('facet', facet_field_name)&.slice(:limit, :offset, :prefix, :sort)&.symbolize_keys || {}

    param_facet = {
      sort: single_valued_param(:"f.#{facet_field_name}.facet.sort"),
      limit: single_valued_param(:"f.#{facet_field_name}.facet.limit")&.to_i,
      offset: single_valued_param(:"f.#{facet_field_name}.facet.offset")&.to_i,
      prefix: single_valued_param(:"f.#{facet_field_name}.facet.prefix")
    }.reject { |_k, v| v.nil? }

    options = defaults.merge(json_facet).merge(param_facet)
    options[:sort] ||= options[:limit].positive? ? 'count' : 'index'

    options
  end

  private

  def search_builder
    request_params if request_params.is_a?(Blacklight::SearchBuilder)
  end

  # Extract JSON Request API parameters from the response header or the request itself
  def json_params
    encoded_json_params = header&.dig('params', 'json')

    return request_params['json'] || {} if encoded_json_params.blank?

    @json_params ||= JSON.parse(encoded_json_params).with_indifferent_access
  end

  # Handle merging solr parameters from the myriad of ways they may be expressed by applying the single-value
  # precedence logic:
  #
  # From https://solr.apache.org/guide/8_8/json-request-api.html#json-parameter-merging :
  # When multiple parameter values conflict with one another a single value is chosen based on the following precedence rules:
  # - Traditional query parameters (q, rows, etc.) take first precedence and are used over any other specified values.
  # - json-prefixed query parameters are considered next.
  # - Values specified in the JSON request body have the lowest precedence and are only used if specified nowhere else.
  #
  # @param [String] key the solr parameter to use
  def single_valued_param(key)
    json_key = QUERY_PARAMETER_TO_JSON_PARAMETER_MAPPING[key]

    params[key] ||
      params["json.#{key}"] ||
      json_params[json_key || key] ||
      json_params.dig(:params, key) ||
      json_params.dig(:params, "json.#{key}")
  end

  # Merge together multi-valued solr parameters from the myriad of ways they may be expressed.
  # Unlike single-valued parameters, this merges all the values across the params.
  #
  # @param [String] key the solr parameter to use
  def multivalued_param(key)
    json_key = QUERY_PARAMETER_TO_JSON_PARAMETER_MAPPING[key]

    [
      params[key],
      params["json.#{key}"],
      json_params[json_key || key],
      json_params.dig(:params, key),
      json_params.dig(:params, "json.#{key}")
    ].select(&:present?).inject([]) do |memo, arr|
      memo.concat(Array.wrap(arr))
    end
  end
end
