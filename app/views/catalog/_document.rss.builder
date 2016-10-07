xml.item do  
  xml.title(blacklight_config.index.document_presenter_class.new(document, self).label || (document.to_semantic_values[:title].first if document.to_semantic_values.key?(:title)))
  xml.link(polymorphic_url(url_for_document(document)))
  xml.author( document.to_semantic_values[:author].first ) if document.to_semantic_values.key? :author
end
