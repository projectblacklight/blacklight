# frozen_string_literal: true
class Blacklight::Solr::InvalidParameter < ArgumentError; end

class Blacklight::Solr::Request < ActiveSupport::HashWithIndifferentAccess
  # @deprecated
  SINGULAR_KEYS = %w(facet fl q qt rows start spellcheck spellcheck.q sort per_page wt hl group defType)

  # @deprecated
  ARRAY_KEYS = %w(facet.field facet.query facet.pivot fq hl.fl)

  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
  end

  def append_query(query)
    if self['q'] || dig(:json, :query, :bool)
      self[:json] ||= { query: { bool: { must: [] } } }
      self[:json][:query] ||= { bool: { must: [] } }
      self[:json][:query][:bool][:must] << query

      if self['q']
        self[:json][:query][:bool][:must] << self['q']
        delete 'q'
      end
    else
      self['q'] = query
    end
  end

  def append_boolean_query(bool_operator, query)
    return if query.blank?

    self[:json] ||= { query: { bool: { bool_operator => [] } } }
    self[:json][:query] ||= { bool: { bool_operator => [] } }
    self[:json][:query][:bool][bool_operator] ||= []

    if self['q']
      self[:json][:query][:bool][:must] ||= []
      self[:json][:query][:bool][:must] << self['q']
      delete 'q'
    end

    self[:json][:query][:bool][bool_operator] << query
  end

  def append_filter_query(query)
    self['fq'] ||= []
    self['fq'] = Array(self['fq']) if self['fq'].is_a? String

    self['fq'] << query
  end

  def append_facet_fields(values)
    self['facet.field'] ||= []
    self['facet.field'] += Array(values)
  end

  def append_facet_query(values)
    self['facet.query'] ||= []
    self['facet.query'] += Array(values)
  end

  def append_facet_pivot(query)
    self['facet.pivot'] ||= []
    self['facet.pivot'] << query
  end

  def append_highlight_field(query)
    self['hl.fl'] ||= []
    self['hl.fl'] << query
  end
end
