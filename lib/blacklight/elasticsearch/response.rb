# frozen_string_literal: true

class Blacklight::Elasticsearch::Response < ActiveSupport::HashWithIndifferentAccess
  include Blacklight::Response::PaginationMethods

  attr_reader :request_params, :search_builder
  attr_accessor :blacklight_config, :options

  delegate :document_factory, to: :blacklight_config

  # @param [Elasticsearch::API::Response] response
  def initialize(api_response, request_params, options = {})
    @search_builder = request_params if request_params.is_a?(Blacklight::SearchBuilder)

    super(ActiveSupport::HashWithIndifferentAccess.new(api_response))
    @request_params = ActiveSupport::HashWithIndifferentAccess.new(request_params)
    self.blacklight_config = options[:blacklight_config]
    self.options = options
  end

  def total
    hits[:total][:value]
  end

  def start
    request_params.fetch('from', 0)
  end

  def documents
    @documents ||= if self[:_source] # handle a get call
                     [document_factory.build(self[:_source].merge(id: self[:_id]), self, options)]
                   elsif self[:docs] # handle mget call
                     self[:docs].filter_map { |doc| document_factory.build(doc[:_source].merge(id: doc[:_id]), self, options) if doc['found'] }
                   else # Search call
                     dig(:hits, :hits).collect { |doc| document_factory.build(doc[:_source].merge(id: doc[:_id]), self, options) }
                   end
  end
  alias docs documents

  # def grouped
  #   @groups ||= self["grouped"].map do |field, group|
  #     # grouped responses can either be grouped by:
  #     #   - field, where this key is the field name, and there will be a list
  #     #        of documents grouped by field value, or:
  #     #   - function, where the key is the function, and the documents will be
  #     #        further grouped by function value, or:
  #     #   - query, where the key is the query, and the matching documents will be
  #     #        in the doclist on THIS object
  #     if group["groups"] # field or function
  #       GroupResponse.new field, group, self
  #     else # query
  #       Group.new field, group, self
  #     end
  #   end
  # end

  # def group key
  #   grouped.find { |x| x.key == key }
  # end

  def aggregations
    @aggregations ||= default_aggregations.merge(facet_field_aggregations) # .merge(facet_query_aggregations).merge(facet_pivot_aggregations).merge(json_facet_aggregations)
  end

  # This is mostly to follow what the Solr Reponse has.
  def params
    raise "Elasticsearch doesn't have params"
  end

  def grouped?
    Array(self[:results]).any? { |result| result[:_group].present? }
  end

  def spelling
    raise "XXXXXX"
    nil
  end

  def more_like _document
    []
  end

  # TODO: Same implementation as solr, move to mixin?
  def export_formats
    documents.map { |x| x.export_formats.keys }.flatten.uniq
  end

  def rows
    search_builder&.rows || hits[:hits].length
  end

  private

  # @return [Hash] establish a null object pattern for facet data look-up, allowing
  #   the response and applied parameters to get passed through even if there was no
  #   facet data in the response
  def default_aggregations
    @default_aggregations ||= begin
      h = Hash.new { |_hash, key| null_facet_field_object(key) }
      h.with_indifferent_access
    end
  end

  # @return [Blacklight::Solr::Response::FacetField] a "null object" facet field
  def null_facet_field_object(key)
    Blacklight::Solr::Response::FacetField.new(key, [], { response: self })
  end

  ##
  # Convert Solr's facet_field response into
  # a hash of Blacklight::Solr::Response::Facet::FacetField objects
  def facet_field_aggregations
    self['aggregations'].each_with_object({}) do |(aggregation_name, data), hash|
      facet_field_name = aggregation_name.delete_prefix('bl-')
      items = data['buckets'].map do |bucket|
        value = bucket['key']
        hits = bucket['doc_count']
        Blacklight::Solr::Response::Facets::FacetItem.new(value: value, hits: hits)
      end
      next if items.empty?

      options = {}
      facet_field = Blacklight::Solr::Response::Facets::FacetField.new(facet_field_name, items, options)
      hash[facet_field_name] = facet_field

      # alias all the possible blacklight config names..
      next unless blacklight_config && !blacklight_config.facet_fields[facet_field_name]

      blacklight_config.facet_fields.select { |_k, v| v.field == facet_field_name }.each_key do |key|
        hash[key] = hash[facet_field_name]
      end
    end
  end

  def hits
    self[:hits]
  end
end
