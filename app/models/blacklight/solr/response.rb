class Blacklight::Solr::Response < HashWithIndifferentAccess
  extend Deprecation

  # Using required_dependency to work around Rails autoloading
  # problems when developing blacklight. Without this, any change
  # to this class breaks other classes in this namespace
  require_dependency 'blacklight/solr/response/pagination_methods'
  require_dependency 'blacklight/solr/response/response'
  require_dependency 'blacklight/solr/response/spelling'
  require_dependency 'blacklight/solr/response/facets'
  require_dependency 'blacklight/solr/response/more_like_this'
  require_dependency 'blacklight/solr/response/group_response'
  require_dependency 'blacklight/solr/response/group'

  include PaginationMethods
  include Spelling
  include Facets
  include Response
  include MoreLikeThis

  attr_reader :request_params
  attr_accessor :document_model, :blacklight_config

  def initialize(data, request_params, options = {})
    super(force_to_utf8(data))
    @request_params = request_params
    self.document_model = options[:solr_document_model] || options[:document_model] || SolrDocument
    self.blacklight_config = options[:blacklight_config]
  end

  def header
    self['responseHeader'] || {}
  end

  def params
    header['params'] || request_params
  end

  def start
    params[:start].to_i
  end

  def rows
    params[:rows].to_i
  end

  def sort
    params[:sort]
  end

  def documents
    @documents ||= (response['docs'] || []).collect{|doc| document_model.new(doc, self) }
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
    self.has_key? "grouped"
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
        value.force_encoding("utf-8")  if value.respond_to?(:force_encoding) 
      end
      value
    end
end
