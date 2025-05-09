# frozen_string_literal: true

module Blacklight::Solr
  class AbstractFilterQueryBuilder
    def initialize(blacklight_config:)
      @blacklight_config = blacklight_config
    end

    attr_reader :blacklight_config

    private

    def facet_inclusive_value_to_fq_string(facet_field, values)
      return if values.blank?

      return facet_value_to_fq_string(facet_field, values.first) if values.length == 1

      facet_config = blacklight_config.facet_fields[facet_field]

      local_params = []
      local_params << "tag=#{facet_config.tag}" if facet_config&.tag

      solr_filters = values.each_with_object({}).with_index do |(v, h), index|
        h["f_inclusive.#{facet_field}.#{index}"] = facet_value_to_fq_string(facet_field, v, use_local_params: false)
      end

      filter_query = solr_filters.keys.map do |k|
        "{!query v=$#{k}}"
      end.join(' OR ')

      ["{!lucene#{" #{local_params.join(' ')}" unless local_params.empty?}}#{filter_query}", solr_filters]
    end

    ##
    # Convert a facet/value pair into a solr fq parameter
    # rubocop:disable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity
    def facet_value_to_fq_string(facet_field, value, use_local_params: true)
      facet_config = blacklight_config.facet_fields[facet_field]

      solr_field = facet_config.field if facet_config && !facet_config.query
      solr_field ||= facet_field

      local_params = []
      local_params << "tag=#{facet_config.tag}" if use_local_params && facet_config&.tag

      if facet_config&.query
        if facet_config.query[value]
          facet_config.query[value][:fq]
        else
          # exclude all documents if the custom facet key specified was not found
          '-*:*'
        end
      elsif value.is_a?(Range)
        prefix = "{!#{local_params.join(' ')}}" unless local_params.empty?
        start = value.begin || '*'
        finish = value.end || '*'
        "#{prefix}#{solr_field}:[#{start} TO #{finish}]"
      elsif value == Blacklight::SearchState::FilterField::MISSING
        "-#{solr_field}:[* TO *]"
      else
        "{!term f=#{solr_field}#{" #{local_params.join(' ')}" unless local_params.empty?}}#{convert_to_term_value(value)}"
      end
    end
    # rubocop:enable Metrics/CyclomaticComplexity, Metrics/PerceivedComplexity

    def convert_to_term_value(value)
      case value
      when DateTime, Time
        value.utc.strftime("%Y-%m-%dT%H:%M:%SZ")
      when Date
        value.to_time(:local).strftime("%Y-%m-%dT%H:%M:%SZ")
      else
        value.to_s
      end
    end
  end
end
