class Document < ActiveRecord::Base
  include Blacklight::Document
  
  def to_partial_path
    'catalog/document'
  end

  def key? k
    attributes.has_key? k.to_s
  end

  def _source
    self
  end
end