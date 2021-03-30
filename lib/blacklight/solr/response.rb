# frozen_string_literal: true
class Blacklight::Solr::Response < ActiveSupport::HashWithIndifferentAccess
  extend ActiveSupport::Autoload
  eager_autoload do
    autoload :PaginationMethods
    autoload :Response
    autoload :Spelling
    autoload :Facets
    autoload :MoreLikeThis
    autoload :GroupResponse
    autoload :Group
  end

  include PaginationMethods
  include Spelling
  include Facets
  include Response
  include MoreLikeThis

  attr_reader :request_params
  attr_accessor :blacklight_config, :options

  delegate :document_factory, to: :blacklight_config

  def initialize(data, request_params, options = {})
    super(force_to_utf8(ActiveSupport::HashWithIndifferentAccess.new(data)))
    @request_params = ActiveSupport::HashWithIndifferentAccess.new(request_params)
    self.blacklight_config = options[:blacklight_config]
    self.options = options
  end

  def header
    self['responseHeader'] || {}
  end

  def params
    header['params'] || request_params
  end

  def start
    single_valued_param(:start, json_key: :offset).to_i
  end

  def rows
    single_valued_param(:rows, json_key: :limit).to_i
  end

  def sort
    single_valued_param(:sort)
  end

  def documents
    @documents ||= (response['docs'] || []).collect { |doc| document_factory.build(doc, self, options) }
  end
  alias_method :docs, :documents

  def grouped
    @groups ||= self["grouped"].map do |field, group|
      # grouped responses can either be grouped by:
      #   - field, where this key is the field name, and there will be a list
      #        of documents grouped by field value, or:
      #   - function, where the key is the function, and the documents will be
      #        further grouped by function value, or:
      #   - query, where the key is the query, and the matching documents will be
      #        in the doclist on THIS object
      if group["groups"] # field or function
        GroupResponse.new field, group, self
      else # query
        Group.new field, group, self
      end
    end
  end

  def group key
    grouped.find { |x| x.key == key }
  end

  def grouped?
    key? "grouped"
  end

  def export_formats
    documents.map { |x| x.export_formats.keys }.flatten.uniq
  end

  private

  def force_to_utf8(value)
    case value
    when Hash
      value.each { |k, v| value[k] = force_to_utf8(v) }
    when Array
      value.each { |v| force_to_utf8(v) }
    when String
      if value.encoding != Encoding::UTF_8
        Blacklight.logger&.warn "Found a non utf-8 value in Blacklight::Solr::Response. \"#{value}\" Encoding is #{value.encoding}"
        value.dup.force_encoding('UTF-8')
      else
        value
      end
    end
    value
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
  # @param [String] json_key the alternative key used by the JSON request API
  def single_valued_param(key, json_key: nil)
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
  # @param [String] json_key the alternative key used by the JSON request API
  def multivalued_param(key, json_key: nil)
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
