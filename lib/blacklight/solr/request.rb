# frozen_string_literal: true

class Blacklight::Solr::InvalidParameter < ArgumentError; end

class Blacklight::Solr::Request < ActiveSupport::HashWithIndifferentAccess
  SINGULAR_KEYS = %w(facet fl q qt rows start spellcheck spellcheck.q sort per_page wt hl group defType)
  ARRAY_KEYS = %w(facet.field facet.query facet.pivot fq hl.fl)

  def initialize(constructor = {})
    if constructor.is_a?(Hash)
      super()
      update(constructor)
    else
      super(constructor)
    end
    ARRAY_KEYS.each do |key|
      self[key] ||= []
    end
  end

  def append_filter_query(query)
    self['fq'] << query
  end

  def append_facet_fields(values)
    self['facet.field'] += Array(values)
  end

  def append_facet_query(values)
    self['facet.query'] += Array(values)
  end

  def append_facet_pivot(query)
    self['facet.pivot'] << query
  end

  def append_highlight_field(query)
    self['hl.fl'] << query
  end

  def to_hash
    reject { |key, value| ARRAY_KEYS.include?(key) && value.blank? }
  end
end
