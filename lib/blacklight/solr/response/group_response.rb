# frozen_string_literal: true
class Blacklight::Solr::Response::GroupResponse
  include Blacklight::Solr::Response::PaginationMethods

  attr_reader :key, :group, :response

  def initialize key, group, response
    @key = key
    @group = group
    @response = response
  end

  alias_method :group_field, :key

  def groups
    @groups ||= group["groups"].map do |g|
      Blacklight::Solr::Response::Group.new g[:groupValue], g, self
    end
  end

  def group_limit
    params.fetch(:'group.limit', 1).to_s.to_i
  end

  def total
    # ngroups is only available in Solr 4.1+
    # fall back on the number of facet items for that field?
    (group["ngroups"] || (response.aggregations[key] || []).length).to_s.to_i
  end

  def start
    params[:start].to_s.to_i
  end

  ##
  # Relying on a fallback (method missing) to @response is problematic as it
  # will not evaluate the correct `total` method.
  def empty?
    total.zero?
  end

  ##
  # Overridden from Blacklight::Solr::Response::PaginationMethods to support
  # grouped key specific i18n keys. `key` is the field being grouped
  def entry_name(options)
    I18n.t(
      "blacklight.entry_name.grouped.#{key}",
      default: :'blacklight.entry_name.grouped.default',
      count: options[:count]
    )
  end

  def method_missing meth, *args, &block
    if response.respond_to? meth
      response.send(meth, *args, &block)
    else
      super
    end
  end

  def respond_to_missing? meth, include_private = false
    response.respond_to?(meth) || super
  end
end
