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
    single_valued_param(:start).to_i
  end

  def rows
    single_valued_param(:rows).to_i
  end

  def sort
    single_valued_param(:sort)
  end

  def facet_field_aggregation_options(facet_field_name)
    sort = single_valued_param(:"f.#{facet_field_name}.facet.sort") || single_valued_param(:'facet.sort')
    limit_param = single_valued_param(:"f.#{facet_field_name}.facet.limit") || single_valued_param(:"facet.limit")
    limit = (limit_param.to_i if limit_param.present?) || 100
    offset = single_valued_param(:"f.#{facet_field_name}.facet.offset") || single_valued_param(:"facet.offset")
    prefix = single_valued_param(:"f.#{facet_field_name}.facet.prefix") || single_valued_param(:"facet.prefix")

    {
      sort: sort || (limit.positive? ? 'count' : 'index'),
      limit: limit,
      offset: (offset.to_i if offset.present?) || 0,
      prefix: prefix
    }
  end

  private

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
